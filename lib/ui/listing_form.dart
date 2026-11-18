import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../domain/listing.dart';
import 'home.dart';

class ListingForm extends StatefulWidget {
  final bool en;
  final Listing? listing;
  const ListingForm({super.key, required this.en, this.listing});
  @override
  State<ListingForm> createState() => _ListingFormState();
}

class _ListingFormState extends State<ListingForm> {
  final form = GlobalKey<FormState>();
  late final TextEditingController title, description, area;
  late Category category;
  late ListingKind kind;
  String? photo, photoError;
  bool picking = false;
  String t(String pt, String en) => widget.en ? en : pt;
  @override
  void initState() {
    super.initState();
    final item = widget.listing;
    title = TextEditingController(text: item?.title);
    description = TextEditingController(text: item?.description);
    area = TextEditingController(text: item?.area);
    category = item?.category ?? Category.accessories;
    kind = item?.kind ?? ListingKind.found;
    photo = item?.photo;
  }

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    area.dispose();
    super.dispose();
  }

  Future<void> pickPhoto() async {
    setState(() {
      picking = true;
      photoError = null;
    });
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 75,
        requestFullMetadata: false,
      );
      if (file != null) {
        if (await file.length() > 350000) {
          throw const FormatException(
            'Use PNG/JPEG até 350 KB / up to 350 KB.',
          );
        }
        final encoded = base64Encode(await file.readAsBytes());
        validatePhoto(encoded);
        if (mounted) setState(() => photo = encoded);
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => photoError = t(
            'Foto não carregada. Use PNG/JPEG até 350 KB.',
            'Photo not loaded. Use PNG/JPEG up to 350 KB.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => picking = false);
    }
  }

  Widget field(
    TextEditingController controller,
    String label,
    int max, {
    int lines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      maxLength: max,
      maxLines: lines,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        try {
          validatePublicText(value ?? '', max: max);
          return null;
        } on FormatException catch (e) {
          return e.message;
        }
      },
    ),
  );

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.listing == null
          ? t('Registrar objeto', 'Add a listing')
          : t('Editar objeto', 'Edit listing'),
    ),
    content: SizedBox(
      width: 530,
      child: SingleChildScrollView(
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t(
                  'Demonstração local · use apenas dados fictícios.',
                  'Local demonstration · use fictional data only.',
                ),
                style: const TextStyle(
                  color: teal,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              if (widget.listing == null) ...[
                SegmentedButton<ListingKind>(
                  segments: [
                    ButtonSegment(
                      value: ListingKind.found,
                      label: Text(t('Encontrei', 'Found')),
                      icon: const Icon(Icons.search),
                    ),
                    ButtonSegment(
                      value: ListingKind.lost,
                      label: Text(t('Perdi', 'Lost')),
                      icon: const Icon(Icons.location_searching),
                    ),
                  ],
                  selected: {kind},
                  onSelectionChanged: (value) =>
                      setState(() => kind = value.single),
                ),
                const SizedBox(height: 20),
              ],
              field(title, t('Nome do objeto', 'Item name'), 70),
              DropdownButtonFormField<Category>(
                isExpanded: true,
                initialValue: category,
                decoration: InputDecoration(
                  labelText: t('Categoria', 'Category'),
                ),
                items: Category.values
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(categoryLabel(c, widget.en)),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => category = value!),
              ),
              const SizedBox(height: 20),
              field(
                description,
                t('Descrição pública', 'Public description'),
                400,
                lines: 3,
              ),
              field(
                area,
                t(
                  'Bairro ou espaço público (sem endereço)',
                  'District or public place (no address)',
                ),
                60,
              ),
              Text(
                t(
                  'Não inclua telefone, e-mail, coordenadas, nomes completos ou documentos. Guarde detalhes de identificação para verificar a posse presencialmente.',
                  'Do not include phone numbers, email, coordinates, full names or documents. Keep identifying details private for an in-person ownership check.',
                ),
                style: const TextStyle(fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 16),
              if (photo != null) ...[
                Image.memory(
                  base64Decode(photo!),
                  height: 130,
                  semanticLabel: t('Foto do objeto', 'Item photo'),
                  errorBuilder: (_, _, _) =>
                      const Icon(Icons.broken_image_outlined),
                ),
                TextButton.icon(
                  onPressed: picking
                      ? null
                      : () => setState(() => photo = null),
                  icon: const Icon(Icons.delete_outline),
                  label: Text(t('Remover foto', 'Remove photo')),
                ),
              ],
              OutlinedButton.icon(
                onPressed: picking ? null : pickPhoto,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(
                  picking
                      ? t('Carregando…', 'Loading…')
                      : t(
                          'Escolher foto · PNG/JPEG',
                          'Choose photo · PNG/JPEG',
                        ),
                ),
              ),
              if (photoError != null)
                Text(
                  photoError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              Text(
                t(
                  'Até 350 KB. Apenas neste navegador. Não fotografe pessoas, documentos ou detalhes sensíveis.',
                  'Up to 350 KB. Only in this browser. Avoid people, documents or sensitive details.',
                ),
                style: const TextStyle(fontSize: 12, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: picking ? null : () => Navigator.pop(context),
        child: Text(t('Cancelar', 'Cancel')),
      ),
      FilledButton(
        onPressed: picking
            ? null
            : () {
                if (!form.currentState!.validate()) return;
                final item = widget.listing == null
                    ? Listing.create(
                        id: DateTime.now().microsecondsSinceEpoch.toString(),
                        title: title.text,
                        description: description.text,
                        area: area.text,
                        category: category,
                        kind: kind,
                        photo: photo,
                      )
                    : widget.listing!.edit(
                        title: title.text,
                        description: description.text,
                        area: area.text,
                        category: category,
                        photo: photo,
                      );
                Navigator.pop(context, item);
              },
        child: Text(t('Salvar neste navegador', 'Save in this browser')),
      ),
    ],
  );
}
