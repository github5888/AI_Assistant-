import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app_state.dart';
import '../store_api.dart';
import '../theme.dart';
import '../widgets.dart';

class AdminHomeBannersScreen extends StatefulWidget {
  const AdminHomeBannersScreen({super.key, required this.api, required this.adminToken});

  final StoreApi api;
  final String adminToken;

  @override
  State<AdminHomeBannersScreen> createState() => _AdminHomeBannersScreenState();
}

class _AdminHomeBannersScreenState extends State<AdminHomeBannersScreen> {
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> _banners = const [];
  bool _loading = true;
  bool _saving = false;
  int? _uploadingIndex;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBanners();
  }

  Future<void> _loadBanners() async {
    setState(() { _loading = true; _error = null; });
    try {
      final banners = await widget.api.homeHeroBanners();
      if (mounted) setState(() { _banners = banners; _loading = false; });
    } on StoreApiException catch (error) {
      if (mounted) setState(() { _error = error.message; _loading = false; });
    } catch (_) {
      if (mounted) setState(() {
        _error = 'Homepage banners could not be loaded. Check the connection and try again.';
        _loading = false;
      });
    }
  }

  void _updateBanner(int index, String key, Object? value) {
    final updated = List<Map<String, dynamic>>.of(_banners);
    updated[index] = Map<String, dynamic>.of(updated[index])..[key] = value;
    setState(() => _banners = updated);
  }

  void _addBanner() {
    final id = 'mobile-banner-${DateTime.now().millisecondsSinceEpoch}';
    setState(() => _banners = [..._banners, {
      'id': id,
      'badge': 'ITS CLEAR',
      'headline': 'Your banner headline',
      'subtitle': 'Add a short message for customers.',
      'primaryCtaText': 'Shop now',
      'primaryCtaLink': '/shop',
      'imageUrl': '',
      'isActive': true,
    }]);
  }

  void _moveBanner(int index, int direction) {
    final target = index + direction;
    if (target < 0 || target >= _banners.length) return;
    final updated = List<Map<String, dynamic>>.of(_banners);
    final banner = updated.removeAt(index);
    updated.insert(target, banner);
    setState(() => _banners = updated);
  }

  Future<void> _pickBannerImage(int index) async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1440,
        maxHeight: 900,
        imageQuality: 82,
      );
      if (picked == null || !mounted) return;
      if (await picked.length() > 10 * 1024 * 1024) {
        _showMessage('Choose an image smaller than 10 MB.');
        return;
      }
      setState(() { _uploadingIndex = index; _error = null; });
      final url = await widget.api.uploadAdminImage(widget.adminToken, picked.path);
      if (!mounted) return;
      _updateBanner(index, 'imageUrl', url);
      _showMessage('Banner image uploaded. Tap Save banners to publish it.');
    } on StoreApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) _showMessage('The gallery image could not be uploaded. Try another image.');
    } finally {
      if (mounted) setState(() => _uploadingIndex = null);
    }
  }

  Future<void> _saveBanners() async {
    if (_saving || _uploadingIndex != null) return;
    final incomplete = _banners.indexWhere((banner) =>
        (banner['headline'] as String? ?? '').trim().isEmpty ||
        (banner['imageUrl'] as String? ?? '').trim().isEmpty);
    if (incomplete != -1) {
      _showMessage('Banner ${incomplete + 1} needs a headline and an image before saving.');
      return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      await widget.api.saveAdminHeroBanners(widget.adminToken, _banners);
      if (!mounted) return;
      await AppScope.of(context).refreshHomeHeroBanners();
      if (!mounted) return;
      _showMessage('Homepage banners saved. Active slides are now live.');
    } on StoreApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Banners could not be saved. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _resolvedImageUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri?.hasScheme == true ? value : widget.api.base.resolve(value).toString();
  }

  @override
  Widget build(BuildContext context) => AppPage(child: Column(children: [
    const AppTopBar(title: 'Homepage banners', subtitle: 'Admin storefront content', back: true),
    Expanded(child: ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      children: [
        SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Banner image guide', style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.ink)),
          const SizedBox(height: 6),
          const Text('The mobile banner frame is about 1200 × 720 px (5:3). Upload the product visual for the right side: 1000 × 1000 px is recommended; transparent PNG works best. JPG, PNG or WebP, max 10 MB. Gallery images are resized on-device to reduce upload and loading time. Headline and copy are placed separately on the left.',
            style: TextStyle(fontSize: 13, height: 1.45, color: AppColors.muted)),
        ])),
        if (_error != null) Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
          child: StoreNotice(message: _error!, onRetry: _loadBanners)),
        if (_loading) const Padding(padding: EdgeInsets.all(28),
          child: Center(child: CircularProgressIndicator())),
        if (!_loading) ...[
          Padding(padding: const EdgeInsets.fromLTRB(20, 4, 20, 8), child: Row(children: [
            Expanded(child: Text('${_banners.length} banner${_banners.length == 1 ? '' : 's'}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900))),
            OutlinedButton.icon(onPressed: _saving || _uploadingIndex != null ? null : _addBanner,
              icon: const Icon(Icons.add_rounded), label: const Text('Add banner')),
          ])),
          for (var index = 0; index < _banners.length; index++) _bannerCard(index),
          if (_banners.isEmpty) const SectionCard(child: Text(
            'No banners yet. Add a banner to start building the home carousel.',
            style: TextStyle(fontSize: 14, color: AppColors.muted))),
          Padding(padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
            child: SizedBox(width: double.infinity, child: FilledButton.icon(
              onPressed: _saving || _uploadingIndex != null ? null : _saveBanners,
              icon: _saving ? const SizedBox.square(dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined),
              label: Text(_saving ? 'SAVING…' : 'SAVE BANNERS'),
            ))),
        ],
      ],
    )),
  ]));

  Widget _bannerCard(int index) {
    final banner = _banners[index];
    final id = banner['id']?.toString() ?? 'banner-$index';
    final image = banner['imageUrl'] is String ? (banner['imageUrl'] as String).trim() : '';
    final active = banner['isActive'] != false;
    return SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text('Banner ${index + 1}', style: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.ink))),
        IconButton(tooltip: 'Move banner up', onPressed: index == 0 || _saving || _uploadingIndex != null
          ? null : () => _moveBanner(index, -1),
          icon: const Icon(Icons.arrow_upward_rounded)),
        IconButton(tooltip: 'Move banner down', onPressed: index == _banners.length - 1 || _saving || _uploadingIndex != null
          ? null : () => _moveBanner(index, 1), icon: const Icon(Icons.arrow_downward_rounded)),
        IconButton(tooltip: 'Remove banner', onPressed: _saving || _uploadingIndex != null
          ? null : () => setState(() => _banners = [..._banners]..removeAt(index)),
          icon: const Icon(Icons.delete_outline, color: AppColors.orange)),
      ]),
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: const Text('Show this banner'),
        value: active,
        onChanged: _saving ? null : (value) => _updateBanner(index, 'isActive', value),
      ),
      if (image.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 10),
        child: ClipRRect(borderRadius: BorderRadius.circular(14),
          child: Image.network(_resolvedImageUrl(image), height: 150, width: double.infinity,
            fit: BoxFit.contain, errorBuilder: (_, __, ___) => Container(height: 90,
              alignment: Alignment.center, color: AppColors.cream,
              child: const Text('Image preview unavailable', style: TextStyle(color: AppColors.muted))))),
      ),
      SizedBox(width: double.infinity, child: OutlinedButton.icon(
        onPressed: _saving || _uploadingIndex != null ? null : () => _pickBannerImage(index),
        icon: _uploadingIndex == index
            ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.photo_library_outlined),
        label: Text(_uploadingIndex == index ? 'UPLOADING IMAGE…' : 'CHOOSE IMAGE FROM GALLERY'),
      )),
      const SizedBox(height: 4),
      _textField(index, 'badge', 'Small label', maxLength: 32),
      _textField(index, 'headline', 'Banner headline', maxLength: 70, maxLines: 2),
      _textField(index, 'subtitle', 'Supporting text', maxLength: 150, maxLines: 3),
      _textField(index, 'primaryCtaText', 'Button label', maxLength: 28),
      _textField(index, 'primaryCtaLink', 'Button destination (e.g. /shop)', maxLength: 120),
      Text('Banner ID: $id', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
    ]));
  }

  Widget _textField(int index, String key, String label, {
    int maxLength = 100, int maxLines = 1,
  }) {
    final initial = _banners[index][key];
    return Padding(padding: const EdgeInsets.only(top: 9), child: TextFormField(
      key: ValueKey('${_banners[index]['id']}-$key'),
      initialValue: initial is String ? initial : '',
      maxLength: maxLength,
      maxLines: maxLines,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(labelText: label, counterText: '', isDense: true),
      onChanged: (value) => _updateBanner(index, key, value),
    ));
  }
}
