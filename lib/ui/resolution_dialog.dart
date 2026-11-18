import 'package:flutter/material.dart';
import '../domain/listing.dart';

class ResolutionDialog extends StatefulWidget {
  final bool en;
  const ResolutionDialog({super.key, required this.en});
  @override
  State<ResolutionDialog> createState() => _ResolutionDialogState();
}

class _ResolutionDialogState extends State<ResolutionDialog> {
  final note = TextEditingController();
  final form = GlobalKey<FormState>();
  bool confirmed = false;
  String t(String pt, String en) => widget.en ? en : pt;
  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(t('Concluir demonstração', 'Complete demonstration')),
    content: SizedBox(
      width: 440,
      child: SingleChildScrollView(
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                t(
                  'Esta ação registra uma resolução simulada. Não confirma uma devolução real e encerra a edição do objeto.',
                  'This records a simulated resolution. It does not confirm a real return and makes this listing read-only.',
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: note,
                maxLength: 160,
                decoration: InputDecoration(
                  labelText: t('Nota da simulação', 'Simulation note'),
                ),
                validator: (v) {
                  try {
                    validatePublicText(v ?? '', max: 160);
                    return null;
                  } on FormatException catch (e) {
                    return e.message;
                  }
                },
              ),
              CheckboxListTile(
                value: confirmed,
                onChanged: (v) => setState(() => confirmed = v ?? false),
                title: Text(
                  t(
                    'Entendo que é uma simulação local',
                    'I understand this is a local simulation',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(t('Cancelar', 'Cancel')),
      ),
      FilledButton(
        onPressed: confirmed
            ? () {
                if (form.currentState!.validate()) {
                  Navigator.pop(context, note.text);
                }
              }
            : null,
        child: Text(t('Concluir simulação', 'Complete simulation')),
      ),
    ],
  );
}
