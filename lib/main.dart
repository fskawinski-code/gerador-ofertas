import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
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
  final _textoCtrl = TextEditingController();

  String _loja = "Shopee";
  final _emojis = {"Shopee": "🛍️", "Mercado Livre": "📦"};

  List<String> _templates = [
    "🔥 OFERTA IMPERDÍVEL!\n\n{loja} {emoji}\n\n👉 {link}\n\nCorre que é por tempo limitado! ⏰",
    "😱 Achei esse produto incrível!\n\n💰 Melhor preço {emoji}\n\n{link}",
    "⚡ PROMOÇÃO RELÂMPAGO ⚡\n\n{link}\n\nAproveite antes que acabe!",
  ];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  
