import 'dart:convert';
import 'package:flutter/material.dart';
import '../domain/listing.dart';
import '../domain/listing_repository.dart';
import '../data/demo_listings.dart';
import 'listing_form.dart';
import 'language_button.dart';
import 'resolution_dialog.dart';

const ink = Color(0xff173b36);
const teal = Color(0xff176b60);
String categoryLabel(Category value, bool en) => (en
    ? ['Accessories', 'Electronics', 'Documents', 'Bags', 'Pets', 'Other']
    : [
        'Acessórios',
        'Eletrônicos',
        'Documentos',
        'Bolsas',
        'Animais',
        'Outros',
      ])[value.index];
IconData categoryIcon(Category value) => [
  Icons.key_rounded,
  Icons.headphones_rounded,
  Icons.badge_outlined,
  Icons.backpack_outlined,
  Icons.pets_outlined,
  Icons.inventory_2_outlined,
][value.index];

class Home extends StatefulWidget {
  final Future<ListingRepository> Function() repository;
  const Home({super.key, required this.repository});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  ListingRepository? repository;
  List<Listing> items = [];
  bool loading = true, busy = false, en = false;
  String? error;
  String query = '';
  Category? category;
  int tab = 0;
  final searchController = TextEditingController();
  String t(String pt, String english) => en ? english : pt;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final repo = await widget.repository();
      final result = await repo.load();
      if (mounted) {
        setState(() {
          repository = repo;
          items = result;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
          error = e.toString();
        });
      }
    }
  }

  Future<bool> save(List<Listing> next) async {
    if (busy || repository == null) return false;
    setState(() => busy = true);
    final previous = items;
    try {
      await repository!.save(next);
      if (!mounted) return false;
      setState(() => items = next);
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${t('Não foi possível salvar', 'Could not save')}: $e',
            ),
            action: SnackBarAction(
              label: t('Tentar novamente', 'Retry'),
              onPressed: () {
                if (identical(items, previous)) {
                  save(next);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        t(
                          'Os registros mudaram. Revise o cadastro antes de tentar novamente.',
                          'Listings changed. Review your listing before retrying.',
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> edit([Listing? listing]) async {
    final result = await showDialog<Listing>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ListingForm(en: en, listing: listing),
    );
    if (result != null && mounted) {
      final ok = await save([
        result,
        ...items.where((item) => item.id != result.id),
      ]);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              t(
                'Registro salvo neste navegador.',
                'Listing saved in this browser.',
              ),
            ),
          ),
        );
      }
    }
  }

  Future<void> details(Listing listing) async {
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(listing.title),
        content: SizedBox(
          width: 470,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (listing.photo != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(
                      base64Decode(listing.photo!),
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.broken_image_outlined),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(listing.description),
                const SizedBox(height: 16),
                Text(
                  '${t('Região aproximada', 'Approximate area')}: ${listing.area}',
                ),
                const SizedBox(height: 16),
                Text(
                  t(
                    'Apenas demonstração local. Combine uma verificação presencial em local público. Não exponha contatos nem detalhes que só o proprietário conhece.',
                    'Local demonstration only. Verify ownership in a public place. Keep contact details and identifying secrets private.',
                  ),
                ),
                if (listing.resolution != null) ...[
                  const Divider(),
                  Text(
                    '${t('Resolução simulada', 'Simulated resolution')}: ${listing.resolution}',
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('Fechar', 'Close')),
          ),
          if (listing.status == ListingStatus.open) ...[
            TextButton(
              onPressed: () => Navigator.pop(context, 'edit'),
              child: Text(t('Editar', 'Edit')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, 'resolve'),
              child: Text(t('Simular resolução', 'Simulate resolution')),
            ),
          ],
        ],
      ),
    );
    if (!mounted) return;
    if (action == 'edit') await edit(listing);
    if (action == 'resolve' && mounted) await resolve(listing);
  }

  Future<void> resolve(Listing listing) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => ResolutionDialog(en: en),
    );
    if (result != null && mounted) {
      final resolved = listing.resolve(result, confirmed: true);
      await save(
        items.map((item) => item.id == listing.id ? resolved : item).toList(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = searchListings(
      items,
      query: query,
      category: category,
      kind: tab == 1
          ? ListingKind.found
          : tab == 2
          ? ListingKind.lost
          : null,
      status: tab == 3 ? ListingStatus.resolved : ListingStatus.open,
    );
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 84,
        titleSpacing: 24,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: teal,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.all_inclusive, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'reencontra',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    color: ink,
                    letterSpacing: -1,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          LanguageButton(en: en, onChanged: () => setState(() => en = !en)),
          const SizedBox(width: 20),
        ],
      ),
      body: loading
          ? Center(
              child: Semantics(
                label: t('Carregando registros', 'Loading listings'),
                child: const CircularProgressIndicator(),
              ),
            )
          : error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_outlined, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      t(
                        'Seus dados não foram alterados.',
                        'Your data has not been changed.',
                      ),
                    ),
                    Text(error!),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: load,
                      child: Text(t('Tentar novamente', 'Try again')),
                    ),
                  ],
                ),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 760;
                return SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: wide ? 32 : 20,
                          vertical: 28,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _pill(
                                  Icons.science_outlined,
                                  t(
                                    'DEMONSTRAÇÃO LOCAL',
                                    'LOCAL DEMONSTRATION',
                                  ),
                                ),
                                Text(
                                  t(
                                    'Somente neste navegador · sem login ou envio',
                                    'Only in this browser · no login or uploads',
                                  ),
                                  style: const TextStyle(
                                    color: Color(0xff52645e),
                                    height: 2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 26),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(wide ? 38 : 24),
                              decoration: BoxDecoration(
                                color: const Color(0xffe3ece5),
                                borderRadius: BorderRadius.circular(26),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          t(
                                            'PEQUENOS GESTOS, NOVOS REENCONTROS',
                                            'SMALL ACTS, HAPPY REUNIONS',
                                          ),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            letterSpacing: 1.6,
                                            fontWeight: FontWeight.w700,
                                            color: teal,
                                          ),
                                        ),
                                        const SizedBox(height: 18),
                                        Text(
                                          t(
                                            'Algo se perdeu.\nA gente ajuda a encontrar.',
                                            'Something went missing.\nLet’s find it together.',
                                          ),
                                          style: TextStyle(
                                            fontSize: wide ? 39 : 29,
                                            height: 1.12,
                                            letterSpacing: -1.2,
                                            fontWeight: FontWeight.w800,
                                            color: ink,
                                          ),
                                        ),
                                        const SizedBox(height: 18),
                                        Text(
                                          t(
                                            'Um ponto de encontro para objetos e suas histórias.\nExplore, registre e aprenda a conectar pessoas com cuidado.',
                                            'A meeting place for belongings and their stories.\nExplore, list and learn to reconnect people with care.',
                                          ),
                                          style: const TextStyle(
                                            height: 1.6,
                                            color: Color(0xff405d53),
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        FilledButton.icon(
                                          onPressed: busy ? null : () => edit(),
                                          icon: const Icon(Icons.add),
                                          label: Text(
                                            t(
                                              'Registrar objeto',
                                              'Add a listing',
                                            ),
                                          ),
                                          style: FilledButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 22,
                                              vertical: 21,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (wide) ...[
                                    const SizedBox(width: 28),
                                    Transform.rotate(
                                      angle: -.09,
                                      child: Container(
                                        width: 190,
                                        height: 190,
                                        decoration: BoxDecoration(
                                          color: const Color(0xfffaf7e9),
                                          borderRadius: BorderRadius.circular(
                                            36,
                                          ),
                                        ),
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            const Icon(
                                              Icons.travel_explore_rounded,
                                              size: 120,
                                              color: teal,
                                            ),
                                            Positioned(
                                              bottom: 15,
                                              right: 15,
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  10,
                                                ),
                                                decoration: const BoxDecoration(
                                                  color: Color(0xffefc270),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.favorite_outline,
                                                  color: ink,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 26),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _stat(
                                  t('Encontrados', 'Found'),
                                  items
                                      .where(
                                        (i) =>
                                            i.kind == ListingKind.found &&
                                            i.status == ListingStatus.open,
                                      )
                                      .length,
                                  Icons.search,
                                ),
                                _stat(
                                  t('Perdidos', 'Lost'),
                                  items
                                      .where(
                                        (i) =>
                                            i.kind == ListingKind.lost &&
                                            i.status == ListingStatus.open,
                                      )
                                      .length,
                                  Icons.location_searching,
                                ),
                                _stat(
                                  t(
                                    'Resolvidos · simulação',
                                    'Resolved · simulation',
                                  ),
                                  items
                                      .where(
                                        (i) =>
                                            i.status == ListingStatus.resolved,
                                      )
                                      .length,
                                  Icons.check_circle_outline,
                                ),
                              ],
                            ),
                            const SizedBox(height: 36),
                            Text(
                              t(
                                'O próximo reencontro começa aqui',
                                'The next reunion starts here',
                              ),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: ink,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              t(
                                'Busque por objeto ou região. Nunca informe endereço exato ou contato.',
                                'Search by item or area. Never include exact addresses or contact information.',
                              ),
                              style: const TextStyle(color: Color(0xff52645e)),
                            ),
                            const SizedBox(height: 22),
                            TextField(
                              controller: searchController,
                              onChanged: (v) => setState(() => query = v),
                              decoration: InputDecoration(
                                labelText: t(
                                  'Buscar objeto ou região',
                                  'Search items or areas',
                                ),
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: query.isNotEmpty
                                    ? IconButton(
                                        tooltip: t(
                                          'Limpar busca',
                                          'Clear search',
                                        ),
                                        icon: const Icon(Icons.close),
                                        onPressed: () => setState(() {
                                          query = '';
                                          searchController.clear();
                                        }),
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                for (var i = 0; i < 4; i++)
                                  ChoiceChip(
                                    selected: tab == i,
                                    onSelected: (_) => setState(() => tab = i),
                                    label: Text(
                                      (en
                                          ? [
                                              'Open listings',
                                              'Found',
                                              'Lost',
                                              'Resolved',
                                            ]
                                          : [
                                              'Em aberto',
                                              'Encontrados',
                                              'Perdidos',
                                              'Resolvidos',
                                            ])[i],
                                    ),
                                  ),
                                SizedBox(
                                  width: 205,
                                  child: DropdownButtonFormField<Category?>(
                                    isExpanded: true,
                                    initialValue: category,
                                    decoration: InputDecoration(
                                      labelText: t('Categoria', 'Category'),
                                      isDense: true,
                                    ),
                                    items: [
                                      DropdownMenuItem(
                                        value: null,
                                        child: Text(
                                          t('Todas', 'All categories'),
                                        ),
                                      ),
                                      ...Category.values.map(
                                        (c) => DropdownMenuItem(
                                          value: c,
                                          child: Text(categoryLabel(c, en)),
                                        ),
                                      ),
                                    ],
                                    onChanged: (v) =>
                                        setState(() => category = v),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),
                            Text(
                              '${filtered.length} ${t('registros', 'listings')}',
                              style: const TextStyle(color: Color(0xff52645e)),
                            ),
                            const SizedBox(height: 16),
                            if (filtered.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.manage_search,
                                      size: 52,
                                      color: teal,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      t(
                                        'Nenhum objeto por aqui ainda',
                                        'No listings here yet',
                                      ),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 20,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      t(
                                        'Experimente outra busca ou registre um objeto.',
                                        'Try another search or add a listing.',
                                      ),
                                    ),
                                    if (items.isEmpty) ...[
                                      const SizedBox(height: 18),
                                      OutlinedButton.icon(
                                        onPressed: busy
                                            ? null
                                            : () => save(demoListings()),
                                        icon: const Icon(
                                          Icons.science_outlined,
                                        ),
                                        label: Text(
                                          t(
                                            'Carregar 3 exemplos fictícios',
                                            'Load 3 fictional examples',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              )
                            else
                              LayoutBuilder(
                                builder: (context, box) {
                                  final columns = box.maxWidth >= 950
                                      ? 3
                                      : box.maxWidth >= 620
                                      ? 2
                                      : 1;
                                  final width =
                                      (box.maxWidth - (columns - 1) * 18) /
                                      columns;
                                  return Wrap(
                                    spacing: 18,
                                    runSpacing: 18,
                                    children: filtered
                                        .map(
                                          (item) => SizedBox(
                                            width: width,
                                            child: _card(item),
                                          ),
                                        )
                                        .toList(),
                                  );
                                },
                              ),
                            const SizedBox(height: 36),
                            const Divider(),
                            const SizedBox(height: 16),
                            Text(
                              t(
                                'Cuidado faz parte do reencontro.',
                                'Care is part of every reunion.',
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: ink,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              t(
                                'Dados locais podem ser apagados pelo navegador. Fotos ficam apenas neste dispositivo. Não use dados pessoais nesta demonstração.',
                                'Browser data can be cleared. Photos remain on this device. Do not use personal data in this demonstration.',
                              ),
                              style: const TextStyle(
                                color: Color(0xff52645e),
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Reencontra · Kleber Andrade · Flutter classroom project',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _pill(IconData icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0xfff9e9c9),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: ink),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
        ),
      ],
    ),
  );

  Widget _stat(String label, int count, IconData icon) => Container(
    constraints: const BoxConstraints(maxWidth: 350),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: teal, size: 20),
        const SizedBox(width: 10),
        Text(
          '$count',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 21,
            color: ink,
          ),
        ),
        const SizedBox(width: 10),
        Flexible(child: Text(label)),
      ],
    ),
  );

  Widget _card(Listing item) {
    final found = item.kind == ListingKind.found;
    final resolved = item.status == ListingStatus.resolved;
    final color = found ? const Color(0xffe3ece5) : const Color(0xfff3e8d4);
    final stateLabel = resolved
        ? t('Resolvido, simulação', 'Resolved, simulation')
        : found
        ? t('Encontrado', 'Found')
        : t('Perdido', 'Lost');
    return Semantics(
      button: true,
      excludeSemantics: true,
      label:
          '${item.title}. $stateLabel. ${item.description}. ${item.area}. ${categoryLabel(item.category, en)}. ${t('Ver detalhes', 'View details')}',
      onTap: busy ? null : () => details(item),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xffe3e6df)),
        ),
        child: InkWell(
          onTap: busy ? null : () => details(item),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 142,
                width: double.infinity,
                color: color,
                child: item.photo == null
                    ? Center(
                        child: Icon(
                          categoryIcon(item.category),
                          size: 66,
                          color: teal,
                        ),
                      )
                    : Image.memory(
                        base64Decode(item.photo!),
                        fit: BoxFit.cover,
                        semanticLabel: item.title,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.broken_image_outlined),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resolved
                          ? t('RESOLVIDO · SIMULAÇÃO', 'RESOLVED · SIMULATION')
                          : found
                          ? t('ENCONTRADO', 'FOUND')
                          : t('PERDIDO', 'LOST'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: found ? teal : const Color(0xff795422),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        height: 1.5,
                        color: Color(0xff52645e),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Icon(Icons.place_outlined, size: 17, color: teal),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            item.area,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            categoryLabel(item.category, en),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Text(
                          t('Ver detalhes', 'View details'),
                          style: const TextStyle(
                            color: teal,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 17, color: teal),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
