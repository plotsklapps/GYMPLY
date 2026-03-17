import 'package:flutter/material.dart';
import 'package:gymply/screens/profilescreen/metadatatextfield_widget.dart';
import 'package:gymply/services/nostr_service.dart';
import 'package:gymply/services/toast_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ndk/ndk.dart';

class MetaDataForm extends StatefulWidget {
  const MetaDataForm({
    required this.metadata,
    required this.canSign,
    super.key,
  });

  final Metadata? metadata;
  final bool canSign;

  @override
  State<MetaDataForm> createState() => _MetaDataFormState();
}

class _MetaDataFormState extends State<MetaDataForm> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  final TextEditingController _pictureController = TextEditingController();
  final TextEditingController _bannerController = TextEditingController();
  final TextEditingController _nip05Controller = TextEditingController();
  final TextEditingController _lud16Controller = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _populateFields();
  }

  @override
  void didUpdateWidget(MetaDataForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.metadata != oldWidget.metadata) {
      _populateFields();
    }
  }

  void _populateFields() {
    if (widget.metadata != null) {
      _nameController.text = widget.metadata!.name ?? '';
      _displayNameController.text = widget.metadata!.displayName ?? '';
      _aboutController.text = widget.metadata!.about ?? '';
      _pictureController.text = widget.metadata!.picture ?? '';
      _bannerController.text = widget.metadata!.banner ?? '';
      _nip05Controller.text = widget.metadata!.nip05 ?? '';
      _lud16Controller.text = widget.metadata!.lud16 ?? '';
      _websiteController.text = widget.metadata!.website ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _displayNameController.dispose();
    _aboutController.dispose();
    _pictureController.dispose();
    _bannerController.dispose();
    _nip05Controller.dispose();
    _lud16Controller.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 48), // Space for overlapping avatar
        const Text(
          'PROFILE DETAILS',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        const SizedBox(height: 16),
        MetadataTextField(
          label: 'Name',
          controller: _nameController,
          hint: 'Your unique name',
        ),
        MetadataTextField(
          label: 'Display Name',
          controller: _displayNameController,
          hint: 'How people see you',
        ),
        MetadataTextField(
          label: 'About',
          controller: _aboutController,
          hint: 'Tell the world about your gains',
          maxLines: 3,
        ),
        MetadataTextField(
          label: 'Picture URL',
          controller: _pictureController,
          hint: 'https://example.com/avatar.jpg',
        ),
        MetadataTextField(
          label: 'Banner URL',
          controller: _bannerController,
          hint: 'https://example.com/banner.jpg',
        ),
        MetadataTextField(
          label: 'NIP-05 Verification',
          controller: _nip05Controller,
          hint: 'user@domain.com',
        ),
        MetadataTextField(
          label: 'Lightning Address (LUD-16)',
          controller: _lud16Controller,
          hint: 'user@getalby.com',
        ),
        MetadataTextField(
          label: 'Website',
          controller: _websiteController,
          hint: 'https://yourwebsite.com',
        ),
        const SizedBox(height: 24),
        if (widget.canSign)
          FilledButton.icon(
            onPressed: _isSaving ? null : _saveMetadata,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.save),
            label: const Text('Save Profile Changes'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          )
        else
          const Text(
            'You must import your private key (nsec) to update your profile.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }

  Future<void> _saveMetadata() async {
    setState(() {
      _isSaving = true;
    });
    try {
      final Metadata metadata =
          widget.metadata?.copyWith() ??
                Metadata(pubKey: Nip19.decode(nostrService.sNpub.value!))
            ..name = _nameController.text.trim()
            ..displayName = _displayNameController.text.trim()
            ..about = _aboutController.text.trim()
            ..picture = _pictureController.text.trim()
            ..banner = _bannerController.text.trim()
            ..nip05 = _nip05Controller.text.trim()
            ..lud16 = _lud16Controller.text.trim()
            ..website = _websiteController.text.trim();

      await nostrService.updateMetadata(metadata);

      if (mounted) {
        // Show toast to user.
        ToastService.showSuccess(
          title: 'Profile Updated',
          subtitle: 'Your changes are now live',
        );
      }
    } on Object catch (e) {
      // Show toast to user.
      ToastService.showError(
        title: 'Update Failed',
        subtitle: '$e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
