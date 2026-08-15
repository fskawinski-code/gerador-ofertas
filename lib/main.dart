import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'dart:async';

void main() => runApp(const MeuApp());

class MeuApp extends StatelessWidget {
  const MeuApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gerador de Ofertas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepOrange,
        useMaterial3: true,
      ),
      home: const TelaInicial(),
    );
  }
}

class TelaInicial extends StatefulWidget {
  const TelaInicial({super.key});
  @override
  State<TelaInicial> createState() => _TelaInicialState();
}

class _TelaInicialState extends State<TelaInicial> {
  final _linkCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();
  final _descontoCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  final _textoCtrl = TextEditingController();

  StreamSubscription? _intentSub;

  String _loja = "Shopee";
  final _emojis = {"Shopee": "🛍️", "Mercado Livre": "📦"};

  final List<String> _templates = [
    "🔥 OFERTA IMPERDÍVEL!\n\n{descricao}\n\n{loja} {emoji}\n\n💵 Por apenas {valor}  {desconto}\n\n👉 {link}\n\nCorre que é por tempo limitado! ⏰",
    "😱 {descricao}\n\n💰 {valor} {desconto} {emoji}\n\n{link}",
    "⚡ PROMOÇÃO RELÂMPAGO ⚡\n\n{descricao}\n💵 {valor} {desconto}\n\n{link}",
  ];

  int _templateSelecionado = 0;

  @override
  void initState() {
    super.initState();
    _carregar();
    _iniciarShareIntent();
  }

  void _iniciarShareIntent() {
    // App já aberto recebendo compartilhamento
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen(
      (files) => _tratarCompartilhamento(files),
      onError: (_) {},
    );

    // App aberto pelo compartilhamento (estava fechado)
    ReceiveSharingIntent.instance.getInitialMedia().then((files) {
      _tratarCompartilhamento(files);
      ReceiveSharingIntent.instance.reset();
    });
  }

  void _tratarCompartilhamento(List<SharedMediaFile> files) {
    if (files.isEmpty) return;
    final url = _extrairLink(files.first.path);
    if (url.isNotEmpty) {
      setState(() => _linkCtrl.text = url);
      _msg("Link recebido! Agora preencha o valor 💰");
    }
  }

  String _extrairLink(String texto) {
    final regex = RegExp(r'https?:\/\/[^\s]+');
    final match = regex.firstMatch(texto);
    return match?.group(0) ?? texto.trim();
  }

  @override
  void dispose() {
    _intentSub?.cancel();
    _linkCtrl.dispose();
    _valorCtrl.dispose();
    _descontoCtrl.dispose();
    _descricaoCtrl.dispose();
    _textoCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _loja = prefs.getString('loja') ?? "Shopee";
      _templateSelecionado = prefs.getInt('template') ?? 0;
    });
  }

  Future<void> _salvar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('loja', _loja);
    await prefs.setInt('template', _templateSelecionado);
  }

  void _msg(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  String _gerarTexto() {
    final valor = _valorCtrl.text.trim();
    final desconto = _descontoCtrl.text.trim();
    return _templates[_templateSelecionado]
        .replaceAll("{loja}", _loja)
        .replaceAll("{emoji}", _emojis[_loja] ?? "")
        .replaceAll("{descricao}", _descricaoCtrl.text.trim())
        .replaceAll("{valor}", valor.isEmpty ? "consulte" : "R\$ $valor")
        .replaceAll("{desconto}", desconto.isEmpty ? "" : "($desconto OFF)")
        .replaceAll("{link}", _linkCtrl.text.trim());
  }

  void _gerar() {
    setState(() => _textoCtrl.text = _gerarTexto());
  }

  void _limpar() {
    setState(() {
      _linkCtrl.clear();
      _valorCtrl.clear();
      _descontoCtrl.clear();
      _descricaoCtrl.clear();
      _textoCtrl.clear();
    });
  }

  void _copiar() {
    Clipboard.setData(ClipboardData(text: _textoCtrl.text));
    _msg("Texto copiado! ✅");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gerador de Ofertas")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: _loja,
              decoration: const InputDecoration(
                labelText: "Loja",
                border: OutlineInputBorder(),
              ),
              items: _emojis.keys
                  .map((l) => DropdownMenuItem(
                        value: l,
                        child: Text("${_emojis[l]} $l"),
                      ))
                  .toList(),
              onChanged: (v) {
                setState(() => _loja = v!);
                _salvar();
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descricaoCtrl,
              decoration: const InputDecoration(
                labelText: "Descrição",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _valorCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: "Valor",
                      prefixText: "R\$ ",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _descontoCtrl,
                    decoration: const InputDecoration(
                      labelText: "Desconto",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _linkCtrl,
              decoration: const InputDecoration(
                labelText: "Link (recebido ao compartilhar)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _templateSelecionado,
              decoration: const InputDecoration(
                labelText: "Modelo de texto",
                border: OutlineInputBorder(),
              ),
              items: List.generate(
                _templates.length,
                (i) => DropdownMenuItem(
                  value: i,
                  child: Text("Modelo ${i + 1}"),
                ),
              ),
              onChanged: (v) {
                setState(() => _templateSelecionado = v!);
                _salvar();
              },
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _gerar,
              icon: const Icon(Icons.auto_awesome),
              label: const Text("Gerar Oferta"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _textoCtrl,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: "Texto gerado",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _copiar,
                    icon: const Icon(Icons.copy),
                    label: const Text("Copiar"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _limpar,
                    icon: const Icon(Icons.cleaning_services),
                    label: const Text("Limpar"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
