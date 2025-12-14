import 'package:flutter_test/flutter_test.dart';
import 'package:dns_manager/models/dns_server.dart';

/// Testes unitários do DNS Manager
/// 
/// Cobre:
/// - Modelo DnsServer
/// - DefaultDnsServers (servidores pré-configurados)
void main() {
  group('DnsServer Model', () {
    test('should create server with required fields', () {
      final server = DnsServer(
        id: 'test-1',
        name: 'Test DNS',
        hostname: 'dns.test.com',
      );

      expect(server.id, 'test-1');
      expect(server.name, 'Test DNS');
      expect(server.hostname, 'dns.test.com');
      expect(server.isCustom, false);
      expect(server.isFavorite, false);
      expect(server.isHidden, false);
    });

    test('should create custom server', () {
      final server = DnsServer(
        id: 'custom-1',
        name: 'Custom DNS',
        hostname: 'custom.dns.com',
        isCustom: true,
        colorValue: 0xFF7C4DFF,
      );

      expect(server.isCustom, true);
      expect(server.colorValue, 0xFF7C4DFF);
    });

    test('should create server with all optional fields', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final server = DnsServer(
        id: 'full-1',
        name: 'Full DNS',
        hostname: 'full.dns.com',
        isCustom: true,
        logoAsset: 'assets/logos/custom.svg',
        customLogoPath: '/path/to/logo.png',
        colorValue: 0xFFFF5722,
        isFavorite: true,
        isHidden: false,
        order: 5,
        createdAt: now,
      );

      expect(server.logoAsset, 'assets/logos/custom.svg');
      expect(server.customLogoPath, '/path/to/logo.png');
      expect(server.isFavorite, true);
      expect(server.order, 5);
      expect(server.createdAt, now);
    });

    test('copyWith should update only specified fields', () {
      final original = DnsServer(
        id: 'orig-1',
        name: 'Original',
        hostname: 'original.dns.com',
        isFavorite: false,
        order: 0,
      );

      final updated = original.copyWith(
        name: 'Updated',
        isFavorite: true,
      );

      expect(updated.id, 'orig-1'); // unchanged
      expect(updated.name, 'Updated'); // changed
      expect(updated.hostname, 'original.dns.com'); // unchanged
      expect(updated.isFavorite, true); // changed
      expect(updated.order, 0); // unchanged
    });

    test('copyWith should clear customLogoPath when clearCustomLogoPath is true', () {
      final server = DnsServer(
        id: 'logo-1',
        name: 'Logo Server',
        hostname: 'logo.dns.com',
        customLogoPath: '/path/to/logo.png',
      );

      final cleared = server.copyWith(clearCustomLogoPath: true);

      expect(cleared.customLogoPath, null);
    });

    test('toJson and fromJson should serialize correctly', () {
      final original = DnsServer(
        id: 'json-1',
        name: 'JSON Test',
        hostname: 'json.dns.com',
        isCustom: true,
        colorValue: 0xFF4285F4,
        isFavorite: true,
        order: 3,
      );

      final json = original.toJson();
      final restored = DnsServer.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.hostname, original.hostname);
      expect(restored.isCustom, original.isCustom);
      expect(restored.colorValue, original.colorValue);
      expect(restored.isFavorite, original.isFavorite);
      expect(restored.order, original.order);
    });

    test('fromJson should handle missing optional fields', () {
      final minimalJson = {
        'id': 'minimal-1',
        'name': 'Minimal',
        'hostname': 'minimal.dns.com',
      };

      final server = DnsServer.fromJson(minimalJson);

      expect(server.id, 'minimal-1');
      expect(server.name, 'Minimal');
      expect(server.hostname, 'minimal.dns.com');
      expect(server.isCustom, false);
      expect(server.isFavorite, false);
      expect(server.isHidden, false);
      expect(server.order, 0);
    });

    test('equality should work correctly', () {
      final server1 = DnsServer(
        id: 'eq-1',
        name: 'Equal',
        hostname: 'equal.dns.com',
      );

      final server2 = DnsServer(
        id: 'eq-1',
        name: 'Equal',
        hostname: 'equal.dns.com',
      );

      final server3 = DnsServer(
        id: 'eq-2',
        name: 'Different',
        hostname: 'different.dns.com',
      );

      expect(server1, server2);
      expect(server1, isNot(server3));
    });
  });

  group('Default DNS Servers', () {
    test('DefaultDnsServers.servers should contain 6 preconfigured servers', () {
      expect(DefaultDnsServers.servers.length, 6);
    });

    test('default servers should have correct hostnames', () {
      final hostnames = DefaultDnsServers.servers.map((s) => s.hostname).toList();
      
      expect(hostnames, contains('1dot1dot1dot1.cloudflare-dns.com'));
      expect(hostnames, contains('dns.google'));
      expect(hostnames, contains('dns.quad9.net'));
      expect(hostnames, contains('dns.adguard.com'));
      expect(hostnames, contains('dns.nextdns.io'));
      expect(hostnames, contains('doh.opendns.com'));
    });

    test('default servers should not be custom', () {
      for (final server in DefaultDnsServers.servers) {
        expect(server.isCustom, false);
      }
    });

    test('default servers should have logo assets', () {
      for (final server in DefaultDnsServers.servers) {
        expect(server.logoAsset, isNotNull);
        expect(server.logoAsset, startsWith('assets/logos/'));
        expect(server.logoAsset, endsWith('.svg'));
      }
    });

    test('default servers should have color values', () {
      for (final server in DefaultDnsServers.servers) {
        expect(server.colorValue, isNotNull);
        expect(server.colorValue! > 0, true);
      }
    });

    test('default servers should have unique IDs', () {
      final ids = DefaultDnsServers.servers.map((s) => s.id).toSet();
      expect(ids.length, DefaultDnsServers.servers.length);
    });

    test('default servers should have sequential order', () {
      for (var i = 0; i < DefaultDnsServers.servers.length; i++) {
        expect(DefaultDnsServers.servers[i].order, i);
      }
    });
  });

  group('DefaultDnsServers Helper Methods', () {
    test('getById should return server when ID exists', () {
      final cloudflare = DefaultDnsServers.getById('cloudflare');
      
      expect(cloudflare, isNotNull);
      expect(cloudflare!.name, 'Cloudflare');
      expect(cloudflare.hostname, '1dot1dot1dot1.cloudflare-dns.com');
    });

    test('getById should return null for non-existent ID', () {
      final nonExistent = DefaultDnsServers.getById('non-existent-id');
      
      expect(nonExistent, isNull);
    });

    test('getByHostname should return server when hostname exists', () {
      final google = DefaultDnsServers.getByHostname('dns.google');
      
      expect(google, isNotNull);
      expect(google!.id, 'google');
      expect(google.name, 'Google');
    });

    test('getByHostname should return null for non-existent hostname', () {
      final nonExistent = DefaultDnsServers.getByHostname('invalid.hostname.com');
      
      expect(nonExistent, isNull);
    });
  });

  group('DnsServer Validation', () {
    test('hostname should be valid DNS format', () {
      // Valid hostnames
      final validHostnames = [
        'dns.google',
        'dns.quad9.net',
        '1dot1dot1dot1.cloudflare-dns.com',
        'dns.adguard.com',
      ];

      for (final hostname in validHostnames) {
        final isValid = hostname.contains('.') && 
                       !hostname.startsWith('.') && 
                       !hostname.endsWith('.');
        expect(isValid, true, reason: '$hostname should be valid');
      }
    });

    test('server name should not be empty', () {
      for (final server in DefaultDnsServers.servers) {
        expect(server.name.isNotEmpty, true);
      }
    });
  });
}
