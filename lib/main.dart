import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final _textoCtrl = TextEditingController();

  String _loja = "Shopee";
  final _emojis = {"Shopee": "🛍️", "Mercado Livre": "📦"};

  List<String> _templates = [
    "🔥 OFERTA IMPERDÍVEL!\n\n{loja} {emoji}\n\n💵 Por apenas {valor}\n\n👉 {link}\n\nCorre que é por tempo limitado! ⏰",
    "😱 Achei esse produto incrível!\n\n💰 Melhor preço: {valor} {emoji}\n\n{link}",
    "⚡ PROMOÇÃO RELÂMPAGO ⚡\n\n💵 {valor}\n\n{link}\n\nAproveite antes que acabe!",
  ];

  int _templateSelecionado = 0;

  @override
  void initState() {
    super.initState();
    _carregar();
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

  String _gerarTexto() {
    final template = _templates[_templateSelecionado];
    return template
        .replaceAll("{loja}", _loja)
        .replaceAll("{emoji}", _emojis[_loja] ?? "")
        .replaceAll("{valor}", _valorCtrl.text.trim().isEmpty
            ? "consulte"
            : "R\$ ${_valorCtrl.text.trim()}")
        .replaceAll("{link}", _linkCtrl.text.trim());
  }

  void _gerar() {
    setState(() {
      _textoCtrl.text = _gerarTexto();
    });
  }

  void _limpar() {
    setState(() {
      _linkCtrl.clear();
      _valorCtrl.clear();
      _textoCtrl.clear();
    });
  }

  void _copiar() {
    Clipboard.setData(ClipboardData(text: _textoCtrl.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Texto copiado! ✅")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gerador de Ofertas"),
      ),
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
              controller: _linkCtrl,
              decoration: const InputDecoration(
                labelText: "Link do produto",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _valorCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: "Valor do produto (ex: 99,90)",
                prefixText: "R\$ ",
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
