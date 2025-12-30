import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/dns_server.dart';
import '../services/permission_service.dart';
import '../theme/app_colors.dart';

/// Dialog unificado para adicionar ou editar servidor DNS
/// 
/// Usado tanto para criar novos servidores quanto para editar existentes.
/// Suporta:
/// - Nome e hostname do servidor
/// - Seleção de cor personalizada
/// - Upload de logo customizado
class ServerFormDialog extends StatefulWidget {
  const ServerFormDialog({
    super.key,
    this.server,
    required this.onSave,
  });

  /// Servidor existente para edição (null para criação)
  final DnsServer? server;
  
  /// Callback quando o servidor é salvo
  final Future<bool> Function(DnsServer server) onSave;

  /// Mostra o dialog de formulário de servidor
  static Future<void> show({
    required BuildContext context,
    DnsServer? server,
    required Future<bool> Function(DnsServer server) onSave,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ServerFormDialog(
        server: server,
        onSave: onSave,
      ),
    );
  }

  @override
  State<ServerFormDialog> createState() => _ServerFormDialogState();
}

class _ServerFormDialogState extends State<ServerFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _hostnameController;
  final _formKey = GlobalKey<FormState>();
  
  int? _selectedColor;
  File? _selectedImage;
  String? _currentLogoPath;
  bool _removeCurrentLogo = false;
  bool _isSaving = false;

  bool get isEditing => widget.server != null;

  static const _availableColors = [
    0xFF004aad, // Azul escuro (primária)
    0xFF5de0e6, // Ciano (secundária)
    0xFFF38020, // Orange
    0xFF4285F4, // Blue
    0xFF68BC71, // Green
    0xFFE91E63, // Pink
    0xFFFF5722, // Deep Orange
    0xFF009688, // Teal Dark
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.server?.name ?? '');
    _hostnameController = TextEditingController(text: widget.server?.hostname ?? '');
    _selectedColor = widget.server?.colorValue;
    _currentLogoPath = widget.server?.customLogoPath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostnameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    // Solicita permissão antes de abrir a galeria
    final hasPermission = await PermissionService.requestPhotosPermission(context);
    
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.orange),
                SizedBox(width: 12),
                Text('Permissão de fotos necessária'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }
    
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 256,
      maxHeight: 256,
      imageQuality: 85,
    );
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _removeCurrentLogo = false;
      });
    }
  }

  void _clearImage() {
    setState(() {
      if (_selectedImage != null) {
        _selectedImage = null;
      } else if (_currentLogoPath != null) {
        _removeCurrentLogo = true;
      }
    });
  }

  Future<String?> _saveImage() async {
    if (_selectedImage == null) return null;
    
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final logosDir = Directory('${appDir.path}/logos');
      if (!await logosDir.exists()) {
        await logosDir.create(recursive: true);
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = _selectedImage!.path.split('.').last;
      final newPath = '${logosDir.path}/custom_$timestamp.$extension';
      
      await _selectedImage!.copy(newPath);
      return newPath;
    } catch (e) {
      debugPrint('Erro ao salvar logo: $e');
      return null;
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    try {
      String? finalLogoPath;
      
      if (isEditing) {
        // Editando servidor existente
        finalLogoPath = _currentLogoPath;
        
        if (_removeCurrentLogo) {
          finalLogoPath = null;
        }
        
        if (_selectedImage != null) {
          finalLogoPath = await _saveImage();
        }
        
        final updatedServer = widget.server!.copyWith(
          name: _nameController.text.trim(),
          hostname: _hostnameController.text.trim(),
          colorValue: _selectedColor,
          customLogoPath: finalLogoPath,
          clearCustomLogoPath: _removeCurrentLogo && _selectedImage == null,
        );
        
        final success = await widget.onSave(updatedServer);
        if (mounted && success) {
          Navigator.pop(context);
        }
      } else {
        // Criando novo servidor
        if (_selectedImage != null) {
          finalLogoPath = await _saveImage();
        }
        
        final newServer = DnsServer(
          id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
          name: _nameController.text.trim(),
          hostname: _hostnameController.text.trim(),
          isCustom: true,
          colorValue: _selectedColor,
          customLogoPath: finalLogoPath,
        );
        
        final success = await widget.onSave(newServer);
        if (mounted && success) {
          Navigator.pop(context);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDarkMode ? AppColors.darkSurface : AppColors.lightSurface;
    final cardBg = isDarkMode ? AppColors.darkCard : AppColors.lightCard;
    
    return AlertDialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(isEditing ? 'Editar Servidor' : 'Novo Servidor DNS'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Seletor de Logo
              _buildLogoSection(cardBg),
              const SizedBox(height: 20),
              
              // Campo Nome
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  hintText: 'Ex: Meu DNS',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Digite um nome';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Campo Hostname
              TextFormField(
                controller: _hostnameController,
                decoration: const InputDecoration(
                  labelText: 'Hostname (DoT)',
                  hintText: 'Ex: dns.example.com',
                  prefixIcon: Icon(Icons.dns_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Digite o hostname';
                  }
                  final regex = RegExp(r'^[a-zA-Z0-9]([a-zA-Z0-9\-\.]*[a-zA-Z0-9])?$');
                  if (!regex.hasMatch(value)) {
                    return 'Hostname inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              // Seletor de Cor
              _buildColorSection(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(isEditing ? 'Salvar' : 'Adicionar'),
        ),
      ],
    );
  }

  Widget _buildLogoSection(Color cardBg) {
    final hasCurrentLogo = _currentLogoPath != null && 
                           !_removeCurrentLogo && 
                           File(_currentLogoPath!).existsSync();
    final hasNewImage = _selectedImage != null;
    final hasLogo = hasNewImage || hasCurrentLogo;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Logo (opcional)',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        Center(
          child: GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hasLogo ? AppColors.secondary : Colors.grey[700]!,
                  width: 2,
                ),
              ),
              child: hasNewImage
                  ? _buildImagePreview(_selectedImage!)
                  : (hasCurrentLogo
                      ? _buildImagePreview(File(_currentLogoPath!))
                      : _buildEmptyLogo()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview(File imageFile) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.file(
            imageFile,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: _clearImage,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.close,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyLogo() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          color: Colors.grey[500],
          size: 32,
        ),
        const SizedBox(height: 4),
        Text(
          'Escolher',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildColorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cor do card',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _availableColors.map((color) {
            final isSelected = _selectedColor == color;
            return GestureDetector(
              onTap: () => setState(() => _selectedColor = color),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Color(color),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Color(color).withValues(alpha:0.5),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
