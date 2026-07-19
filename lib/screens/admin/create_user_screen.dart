import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_ui.dart';

/// Admin -> create a Partner (store) or a TYC Admin account. Generates a
/// password to share (accounts are created ready to sign in).
class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();

  String _type = 'partner'; // 'partner' | 'admin'
  bool _emailInvite = true; // true = email a set-password link
  bool _submitting = false;
  CreatedUser? _result;

  final _storeName = TextEditingController();
  final _address = TextEditingController();
  final _primaryContact = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _fullName = TextEditingController();

  @override
  void dispose() {
    _storeName.dispose();
    _address.dispose();
    _primaryContact.dispose();
    _email.dispose();
    _phone.dispose();
    _fullName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    try {
      final payload = _type == 'partner'
          ? <String, dynamic>{
              'type': 'partner',
              'invite': _emailInvite,
              'email': _email.text.trim(),
              'storeName': _storeName.text.trim(),
              'address': _address.text.trim(),
              'primaryContact': _primaryContact.text.trim(),
              'phone': _phone.text.trim(),
            }
          : <String, dynamic>{
              'type': 'admin',
              'invite': _emailInvite,
              'email': _email.text.trim(),
              'fullName': _fullName.text.trim(),
            };
      final result = await AdminService.createUser(payload);
      if (!mounted) return;
      setState(() => _result = result);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
        );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add account')),
      body: SafeArea(
        child: _result != null
            ? _ResultView(
                result: _result!,
                onDone: () => Navigator.of(context).pop(true),
              )
            : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    final isPartner = _type == 'partner';
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const SectionLabel('Account type'),
          const SizedBox(height: 10),
          Row(
            children: [
              _TypeToggle(
                label: 'Partner store',
                selected: isPartner,
                onTap: () => setState(() => _type = 'partner'),
              ),
              const SizedBox(width: 12),
              _TypeToggle(
                label: 'TYC admin',
                selected: !isPartner,
                onTap: () => setState(() => _type = 'admin'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (isPartner) ...[
            _field(_storeName, 'Store name', required: true),
            _field(_address, 'Address', required: true),
            _field(_primaryContact, 'Primary contact', required: true),
            _field(_email, 'Email', required: true, email: true),
            _field(_phone, 'Phone number',
                required: true, keyboard: TextInputType.phone),
          ] else ...[
            Text(
              'Creates a TYC admin who can see every store and manage accounts.',
              style: GoogleFonts.dmSans(
                  color: AppColors.textMuted, fontSize: 13, height: 1.35),
            ),
            const SizedBox(height: 16),
            _field(_fullName, 'Full name (optional)'),
            _field(_email, 'Email', required: true, email: true),
          ],
          const SizedBox(height: 12),
          const SectionLabel('Send login'),
          const SizedBox(height: 10),
          Row(
            children: [
              _TypeToggle(
                label: 'Email invite',
                selected: _emailInvite,
                onTap: () => setState(() => _emailInvite = true),
              ),
              const SizedBox(width: 12),
              _TypeToggle(
                label: 'Share password',
                selected: !_emailInvite,
                onTap: () => setState(() => _emailInvite = false),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: AppColors.text),
                  )
                : Text(_emailInvite
                    ? 'Create & send invite'
                    : (isPartner ? 'Create store account' : 'Create admin')),
          ),
          const SizedBox(height: 12),
          Text(
            _emailInvite
                ? 'We’ll email them a link to set their own password.'
                : 'The account is created with a password you can share. They '
                    'sign in with their email + that password.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
                color: AppColors.textMuted, fontSize: 12, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    bool email = false,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType:
            email ? TextInputType.emailAddress : (keyboard ?? TextInputType.text),
        autocorrect: !email,
        enableSuggestions: !email,
        textCapitalization:
            email ? TextCapitalization.none : TextCapitalization.words,
        style: const TextStyle(color: AppColors.text),
        decoration: InputDecoration(labelText: label),
        validator: (v) {
          final value = (v ?? '').trim();
          if (required && value.isEmpty) return 'Required';
          if (email && value.isNotEmpty && !value.contains('@')) {
            return 'Enter a valid email';
          }
          return null;
        },
      ),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  const _TypeToggle({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? AppColors.accent : AppColors.border,
                width: selected ? 2 : 1,
              ),
            ),
            child: Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                color: selected ? const Color(0xFF07230A) : AppColors.text,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.result, required this.onDone});

  final CreatedUser result;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final invited = result.invited;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            height: 72,
            width: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accent, width: 2),
            ),
            child: Icon(invited ? Icons.mark_email_read_outlined : Icons.check,
                size: 40, color: AppColors.accent),
          ),
          const SizedBox(height: 16),
          Text(
            invited ? 'Invite sent' : 'Account created',
            style: GoogleFonts.spaceGrotesk(
                fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.text),
          ),
          const SizedBox(height: 6),
          Text(
            invited
                ? 'We emailed a link to set their password. Once they do, they '
                    'can sign in to the app.'
                : 'Share these credentials. The password is shown only once.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 24),
          _CredRow(label: 'EMAIL', value: result.email),
          if (!invited && result.password != null) ...[
            const SizedBox(height: 12),
            _CredRow(label: 'PASSWORD', value: result.password!, mono: true),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(
                  text: 'TYC Partner login\nEmail: ${result.email}\n'
                      'Password: ${result.password}',
                ));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Login copied to clipboard')),
                  );
                }
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy email + password'),
            ),
          ],
          const Spacer(),
          ElevatedButton(onPressed: onDone, child: const Text('Done')),
        ],
      ),
    );
  }
}

class _CredRow extends StatelessWidget {
  const _CredRow({required this.label, required this.value, this.mono = false});
  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(label),
          const SizedBox(height: 6),
          SelectableText(
            value,
            style: mono
                ? GoogleFonts.spaceMono(
                    color: AppColors.accent,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)
                : GoogleFonts.dmSans(color: AppColors.text, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
