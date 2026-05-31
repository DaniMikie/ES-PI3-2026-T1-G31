/*
---------- Tela de Venda de Tokens ----------
- Autora Principal: Ana Luisa Maso Mafra | RA: 25007997
*/

/*
  Tela de criação de anúncio de venda de tokens.

  Funcionalidades:
  - Exibição do saldo de tokens disponíveis do usuário para a startup selecionada
  - Definição de quantidade e preço customizado por token
  - Indicador em tempo real de variação percentual em relação ao preço de mercado
  - Cálculo e exibição do valor total do anúncio conforme o usuário preenche os campos
  - Validação de saldo e preço antes de publicar
  - Confirmação do anúncio com autenticação por senha
*/

import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'startup_details_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Widget principal da tela de criação de anúncio de venda de tokens
class SellScreen extends StatefulWidget {
  final String startupId;
  final String startupName;
  // Preço de mercado atual do token, usado como referência e sugestão de preço
  final double tokenPrice;
  final int totalTokens;
  final String stage;
  final List<String> tags;

  const SellScreen({
    super.key,
    required this.startupId,
    required this.startupName,
    required this.tokenPrice,
    required this.totalTokens,
    required this.stage,
    required this.tags,
  });

  @override
  State<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends State<SellScreen> {
  // Quantidade de tokens que o usuário deseja anunciar
  int quantity = 0;
  // Preço por token definido pelo vendedor (pode diferir do preço de mercado)
  double _customPrice = 0;
  // Getter que calcula o valor total do anúncio com base na quantidade e no preço escolhido
  double get totalValue => quantity * _customPrice;
  // Quantidade de tokens que o usuário possui para a startup em questão
  int _myTokens = 0;
  // Controla o estado de carregamento da consulta de tokens do usuário
  bool _loadingTokens = true;

  // Controllers dos campos de entrada de quantidade e preço
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Preenche o preço com o valor atual do token como sugestão
    _customPrice = widget.tokenPrice;
    _priceController.text = widget.tokenPrice.toStringAsFixed(2).replaceAll('.', ',');
    _loadMyTokens();
  }

  @override
  void dispose() {
    // Libera os controllers para evitar vazamento de memória
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // Busca a carteira do usuário e extrai a quantidade de tokens disponíveis para a startup atual
  Future<void> _loadMyTokens() async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('getWallet');
      final result = await callable.call();
      final data = Map<String, dynamic>.from(result.data as Map);
      final innerData = Map<String, dynamic>.from(data['data'] as Map? ?? data);
      final positions = List<Map<String, dynamic>>.from(
        (innerData['positions'] as List?)?.map((p) => Map<String, dynamic>.from(p as Map)) ?? [],
      );
      // Filtra apenas a posição correspondente à startup sendo anunciada
      final pos = positions.where((p) => p['startupId'] == widget.startupId).toList();
      final rawQty = pos.isNotEmpty ? pos.first['quantity'] : 0;
      if (mounted) {
        setState(() {
          // Garante compatibilidade com diferentes tipos numéricos retornados pelo backend
          _myTokens = rawQty is int ? rawQty : (rawQty is num ? rawQty.toInt() : 0);
          _loadingTokens = false;
        });
      }
    } catch (_) {
      // Em caso de erro, apenas encerra o loading sem travar a interface
      if (mounted) setState(() => _loadingTokens = false);
    }
  }

  // Formata um valor double em reais no padrão (R$ 0,00)
  String _formatMoney(double value) => 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  Widget build(BuildContext context) {
    // Gera as iniciais da startup para exibir no avatar do card
    final logo = widget.startupName.length >= 2
        ? widget.startupName.substring(0, 2).toUpperCase()
        : 'S';
    // O botão de publicar só é habilitado quando quantidade e preço forem válidos
    final bool canSell = quantity > 0 && _customPrice > 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: Image.asset('assets/images/logo.png', width: 150),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Criar anúncio de venda',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Defina a quantidade e o seu preço por token',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 20),

            // Card da startup
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  // Avatar com as iniciais da startup
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(color: const Color(0xFF2E7D32), borderRadius: BorderRadius.circular(12)),
                    child: Center(child: Text(logo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // Nome e primeira tag da startup
                      Text(widget.startupName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(widget.tags.isNotEmpty ? widget.tags.first : '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Tokens disponíveis
            // Exibe spinner enquanto carrega, depois mostra a quantidade de tokens do usuário
            _loadingTokens
                ? const Text('Carregando...', style: TextStyle(color: Colors.grey, fontSize: 13))
                : Text(
                    'Você possui $_myTokens tokens disponíveis',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                  ),
            const SizedBox(height: 4),
            // Preço de mercado exibido como referência para o vendedor definir seu preço
            Text(
              'Preço de mercado atual: ${_formatMoney(widget.tokenPrice)}',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 6),
            // Link para navegar até os detalhes da startup antes de criar o anúncio
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => StartupDetailsScreen(startupId: widget.startupId, startupName: widget.startupName)),
              ),
              child: const Row(children: [
                Text('Quer saber mais informações? ', style: TextStyle(color: Colors.grey, fontSize: 13)),
                Text('Ir para a startup', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 13)),
                Icon(Icons.arrow_forward, size: 14, color: Color(0xFF2E7D32)),
              ]),
            ),
            const SizedBox(height: 28),

            // Quantidade
            const Text('Quantidade de tokens', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Quantos tokens deseja anunciar?', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 10),
            // Campo numérico que atualiza a quantidade do anúncio em tempo real
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                suffixText: 'Tokens',
                suffixStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2),
                ),
              ),
              // Converte o texto para inteiro; usa 0 como fallback se o valor for inválido
              onChanged: (v) => setState(() => quantity = int.tryParse(v) ?? 0),
            ),
            const SizedBox(height: 20),

            // Preço por token
            const Text('Seu preço por token', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            // Exibe o preço de mercado como sugestão ao lado do label
            Row(children: [
              const Text('Preço sugerido (mercado): ', style: TextStyle(color: Colors.grey, fontSize: 13)),
              Text(
                _formatMoney(widget.tokenPrice),
                style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ]),
            const SizedBox(height: 10),
            // Campo decimal que permite ao vendedor definir seu próprio preço por token
            TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: '0,00',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                prefixText: 'R\$ ',
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2),
                ),
              ),
              onChanged: (v) {
                // Substitui vírgula por ponto para compatibilidade com double.tryParse
                final parsed = double.tryParse(v.replaceAll(',', '.')) ?? 0;
                setState(() => _customPrice = parsed);
              },
            ),

            // Indicador de variação em relação ao preço de mercado
            if (_customPrice > 0 && widget.tokenPrice > 0) ...[
              const SizedBox(height: 8),
              Builder(builder: (context) {
                // Calcula a diferença percentual entre o preço do vendedor e o preço de mercado
                final diff = ((_customPrice - widget.tokenPrice) / widget.tokenPrice) * 100;
                final isAbove = diff > 0;
                final isBelow = diff < 0;
                // Exibe ícone e texto indicando se o preço está acima, abaixo ou igual ao mercado
                return Row(children: [
                  Icon(
                    isAbove ? Icons.trending_up : (isBelow ? Icons.trending_down : Icons.trending_flat),
                    size: 16,
                    color: isAbove ? Colors.orange : (isBelow ? Colors.blue : Colors.grey),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isAbove
                        ? '${diff.toStringAsFixed(1)}% acima do mercado'
                        : isBelow
                            ? '${diff.abs().toStringAsFixed(1)}% abaixo do mercado'
                            : 'Igual ao preço de mercado',
                    style: TextStyle(
                      fontSize: 12,
                      color: isAbove ? Colors.orange : (isBelow ? Colors.blue : Colors.grey),
                    ),
                  ),
                ]);
              }),
            ],
            const SizedBox(height: 24),

            // Total do anúncio─────────────────────────────────────────
            const Text('Total do anúncio:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            // Exibe o valor total calculado em destaque para facilitar a revisão do vendedor
            Container(
              width: double.infinity, height: 60,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF2E7D32)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  _formatMoney(totalValue),
                  style: const TextStyle(fontSize: 28, color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Info sobre como funciona
            // Explica ao vendedor que os tokens só são transferidos após a aceitação da oferta
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC8E6C9)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 16, color: Color(0xFF2E7D32)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Seu anúncio ficará visível para compradores no balcão. Os tokens só são transferidos quando alguém aceitar sua oferta.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF2E7D32)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Botão habilitado apenas quando quantidade e preço estão preenchidos corretamente
            SizedBox(
              width: double.infinity, height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: canSell ? _criarAnuncio : null,
                child: const Text('Publicar anúncio', style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Valida os dados antes de abrir o dialog de autenticação para publicar o anúncio
  void _criarAnuncio() async {
    // Impede o anúncio se a quantidade desejada exceder o saldo disponível do usuário
    if (_myTokens < quantity) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Você possui apenas $_myTokens tokens disponíveis'),
            backgroundColor: Color(0xFFB30B0E),
          ),
        );
      }
      return;
    }
    // Impede o anúncio se o preço definido for zero ou negativo
    if (_customPrice <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informe um preço válido por token'), backgroundColor: Color(0xFFB30B0E)),
        );
      }
      return;
    }
    // Dados válidos: abre o dialog de confirmação com senha
    _showAuthDialog();
  }

  // Exibe o dialog de confirmação do anúncio com reautenticação por senha
  void _showAuthDialog() {
    final senhaController = TextEditingController();
    // Controla a visibilidade da senha no campo de texto
    bool senhaVisivel = false;
    showDialog(
      context: context,
      builder: (dialogContext) {
        // Mensagem de erro exibida dentro do dialog
        String? erro;
        // Controla o estado de loading do botão de publicar
        bool loading = false;
        // StatefulBuilder permite atualizar o estado interno do dialog isoladamente
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Confirmar anúncio', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  // Resumo do anúncio
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nome da startup do anúncio
                        Text(widget.startupName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        // Detalhes do anúncio: quantidade, preço unitário e valor total
                        Text('$quantity tokens × ${_formatMoney(_customPrice)}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        Text('Total: ${_formatMoney(totalValue)}', style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),

                  const Text('Digite sua senha para publicar', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 16),
                  // Exibe o container de erro apenas se houver mensagem de erro
                  if (erro != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Text(erro!, style: const TextStyle(color: Color(0xFFB30B0E), fontSize: 13)),
                    ),
                  // Campo de senha com toggle de visibilidade e ícones SVG customizados
                  TextField(
                    controller: senhaController,
                    obscureText: !senhaVisivel,
                    enabled: !loading,
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(12),
                        child: SvgPicture.asset(
                          'assets/icons/password.svg',
                          colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.srcIn),
                          width: 24,
                          height: 24,
                        ),
                      ),
                      // Botão para alternar entre mostrar e ocultar a senha
                      suffixIcon: IconButton(
                        icon: SvgPicture.asset(
                          senhaVisivel
                              ? 'assets/icons/eye_on.svg'
                              : 'assets/icons/eye_off.svg',
                          colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.srcIn),
                          width: 24,
                          height: 24,
                        ),
                        onPressed: () => setDialogState(() => senhaVisivel = !senhaVisivel),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity, height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      // Desabilita o botão enquanto a requisição está em andamento
                      onPressed: loading ? null : () async {
                        if (senhaController.text.isEmpty) {
                          setDialogState(() => erro = 'Informe sua senha');
                          return;
                        }
                        setDialogState(() { loading = true; erro = null; });
                        try {
                          // Reautentica o usuário antes de executar a operação financeira
                          final user = FirebaseAuth.instance.currentUser!;
                          await user.reauthenticateWithCredential(
                            EmailAuthProvider.credential(email: user.email!, password: senhaController.text),
                          );
                          final callable = FirebaseFunctions.instance.httpsCallable('createOffer');
                          await callable.call({
                            'startupId': widget.startupId,
                            'quantity': quantity,
                            // Envia em centavos para o backend (padrão do projeto)
                            'priceCents': (_customPrice * 100).round(),
                          });
                          // Fecha o dialog e exibe confirmação de sucesso na tela anterior
                          if (dialogContext.mounted) Navigator.pop(dialogContext);
                          await Future.delayed(const Duration(milliseconds: 100));
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Anúncio publicado! $quantity tokens por ${_formatMoney(_customPrice)} cada'),
                                backgroundColor: const Color(0xFF2E7D32),
                              ),
                            );
                            Navigator.pop(context);
                          }
                        } on FirebaseAuthException catch (_) {
                          // Senha incorreta: exibe o erro sem fechar o dialog
                          setDialogState(() { erro = 'Senha incorreta'; loading = false; });
                        } on FirebaseFunctionsException catch (e) {
                          // Exibe a mensagem de erro retornada pela Cloud Function
                          setDialogState(() { erro = e.message ?? 'Erro ao publicar anúncio'; loading = false; });
                        } catch (_) {
                          // Captura erros inesperados sem travar a interface
                          setDialogState(() { erro = 'Erro inesperado'; loading = false; });
                        }
                      },
                      // Exibe spinner durante o processamento ou o texto do botão quando disponível
                      child: loading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Publicar', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
