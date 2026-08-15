import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const MeuApp());

class MeuApp extends StatelessWidget {
  const MeuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gerador de Ofertas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
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
  static const _shareChannel = MethodChannel('app.share/link');

  final _linkCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();
  final _tituloCtrl = TextEditingController();

  String _resultado = '';

  @override
  void initState() {
    super.initState();
    _iniciarShareIntent();
  }

  @override
  void dispose() {
    _linkCtrl.dispose();
    _valorCtrl.dispose();
    _tituloCtrl.dispose();
    super.dispose();
  }

  // ===== Recebe link compartilhado (nativo, sem plugin) =====
  void _iniciarShareIntent() {
    // 1. Escuta links que o Android ENVIA (app já aberto ou recém aberto)
    _shareChannel.setMethodCallHandler((call) async {
      if (call.method == 'linkRecebido') {
        final texto = call.arguments as String?;
        _preencherLink(texto);
      }
    });

    // 2. Fallback: busca link inicial (caso o Android não tenha empurrado ainda)
    _buscarLinkCompartilhado();
  }

  Future<void> _buscarLinkCompartilhado() async {
    try {
      final texto = await _shareChannel.invokeMethod<String>('getSharedLink');
      _preencherLink(texto);
    } catch (_) {}
  }

  void _preencherLink(String? texto) {
    if (texto != null && texto.isNotEmpty) {
      setState(() => _linkCtrl.text = _extrairLink(texto));
      _msg("Link recebido! Agora preencha o valor 💰");
    }
  }

  // Extrai a primeira URL de um texto qualquer
  String _extrairLink(String texto) {
    final match = RegExp(r'https?:\/\/[^\s]+').firstMatch(texto);
    return match?.group(0) ?? texto.trim();
  }

  void _msg(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  // ===== Gera a oferta =====
  void _gerarOferta() {
    final link = _linkCtrl.text.trim();
    final valor = _valorCtrl.text.trim();
    final titulo = _tituloCtrl.text.trim();

    if (link.isEmpty || valor.isEmpty) {
      _msg('Preencha o link e o valor!');
      return;
    }

    final texto = StringBuffer();
    if (titulo.isNotEmpty) texto.writeln('🔥 $titulo');
    texto.writeln('💰 Por apenas R\$ $valor');
    texto.writeln('🛒 $link');

    setState(() => _resultado = texto.toString());
  }

  void _copiar() {
    if (_resultado.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _resultado));
    _msg('Oferta copiada! 📋');
  }

  void _limpar() {
    setState(() {
      _linkCtrl.clear();
      _valorCtrl.clear();
      _tituloCtrl.clear();
      _resultado = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerador de Ofertas'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _tituloCtrl,
              decoration: const InputDecoration(
                labelText: 'Título do produto (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _valorCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Valor (R\$)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _linkCtrl,
              decoration: const InputDecoration(
                labelText: 'Link do produto',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _gerarOferta,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Gerar Oferta'),
            ),
            const SizedBox(height: 20),
            if (_resultado.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.deepPurple.shade200),
                ),
                child: SelectableText(
                  _resultado,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _copiar,
                      icon: const Icon(Icons.copy),
                      label: const Text('Copiar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _limpar,
                      icon: const Icon(Icons.clear),
                      label: const Text('Limpar'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
