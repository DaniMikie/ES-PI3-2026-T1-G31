/*
---------- Tela de Compra de Tokens ----------
- Autora Principal: Ana Luisa Maso Mafra | RA: 25007997
*/

/*
  Tela de compra de tokens de uma startup específica.

  Funcionalidades:
  - Listagem de ofertas de venda disponíveis no mercado, ordenadas por menor preço
  - Destaque visual da melhor oferta e indicador de variação em relação ao preço de mercado
  - Atualização da lista via pull-to-refresh
  - Confirmação de compra com resumo da oferta e autenticação por senha
  - Tratamento de saldo insuficiente com dialog dedicado
  - Navegação para a tela de detalhes da startup
*/

import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'startup_details_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Widget principal da tela de compra de tokens, recebe os dados da startup via construtor
class BuyScreen extends StatefulWidget {
  final String startupId;
  final String startupName;
  final double tokenPrice; // preço de mercado, usado como referência
  final int totalTokens;
  final String stage;
  final List<String> tags;

  const BuyScreen({
    super.key,
    required this.startupId,
    required this.startupName,
    required this.tokenPrice,
    required this.totalTokens,
    required this.stage,
    required this.tags,
  });

  @override
  State<BuyScreen> createState() => _BuyScreenState();
}

class _BuyScreenState extends State<BuyScreen> {
  // Lista de ofertas retornadas pelo backend
  List<Map<String, dynamic>> _offers = [];
  // Controla o estado de carregamento das ofertas
  bool _loadingOffers = true;
  // Armazena mensagem de erro caso o carregamento falhe
  String? _offerError;

  @override
  void initState() {
    super.initState();
    // Carrega as ofertas assim que a tela é inicializada
    _loadOffers();
  }

  // Busca as ofertas disponíveis para a startup via Cloud Function
  Future<void> _loadOffers() async {
    setState(() { _loadingOffers = true; _offerError = null; });
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('listOffers');
      final result = await callable.call({'startupId': widget.startupId});
      // Converte o resultado para Map tipado, suportando diferentes formatos de resposta
      final data = Map<String, dynamic>.from(result.data as Map);
      final innerData = Map<String, dynamic>.from(data['data'] as Map? ?? data);
      final offers = List<Map<String, dynamic>>.from(
        (innerData['offers'] as List?)?.map((o) => Map<String, dynamic>.from(o as Map)) ?? [],
      );
      // Ordena por menor preço primeiro
      offers.sort((a, b) {
        final pa = a['priceCents'] is num ? (a['priceCents'] as num).toInt() : 0;
        final pb = b['priceCents'] is num ? (b['priceCents'] as num).toInt() : 0;
        return pa.compareTo(pb);
      });
      // Atualiza o estado somente se o widget ainda estiver montado
      if (mounted) setState(() { _offers = offers; _loadingOffers = false; });
    } catch (e) {
      if (mounted) setState(() { _offerError = 'Não foi possível carregar as ofertas'; _loadingOffers = false; });
    }
  }

  // Formata um valor double em reais no padrão brasileiro (R$ 0,00)
  String _formatMoney(double value) => 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  Widget build(BuildContext context) {
    // Gera as iniciais da startup para exibir no avatar caso não haja imagem
    final logo = widget.startupName.length >= 2
        ? widget.startupName.substring(0, 2).toUpperCase()
        : 'S';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: Image.asset('assets/images/logo.png', width: 150),
        centerTitle: true,
      ),
      // RefreshIndicator permite atualizar a lista de ofertas com gesto de pull-to-refresh
      body: RefreshIndicator(
        color: const Color(0xFF2E7D32),
        onRefresh: _loadOffers,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Comprar tokens',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
              ),
              const SizedBox(height: 6),
              const Text(
                'Escolha uma oferta de vendedor para comprar',
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
                        // Nome da startup
                        Text(widget.startupName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        // Exibe a primeira tag da startup como categoria, se existir
                        Text(widget.tags.isNotEmpty ? widget.tags.first : '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Ver ofertas disponíveis',
                              style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        // Exibe o preço de mercado do token como referência para o investidor
                        Text(
                          'Preço de mercado: ${_formatMoney(widget.tokenPrice)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Link para navegar até a tela de detalhes da startup
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

              // Lista de ofertas
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Ofertas disponíveis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  // Exibe o total de ofertas disponíveis após o carregamento
                  if (!_loadingOffers)
                    Text(
                      '${_offers.length} ${_offers.length == 1 ? 'oferta' : 'ofertas'}',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Ordenadas por menor preço. Puxe para atualizar.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 12),

              // Exibe um indicador de carregamento enquanto as ofertas são buscadas
              if (_loadingOffers)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
                  ),
                )
              // Exibe mensagem de erro com opção de tentar novamente se o carregamento falhar
              else if (_offerError != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(children: [
                      Icon(Icons.error_outline, color: Colors.grey.shade400, size: 40),
                      const SizedBox(height: 8),
                      Text(_offerError!, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 12),
                      TextButton(onPressed: _loadOffers, child: const Text('Tentar novamente', style: TextStyle(color: Color(0xFF2E7D32)))),
                    ]),
                  ),
                )
              // Exibe mensagem informativa quando não há ofertas cadastradas para a startup
              else if (_offers.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(children: [
                      Icon(Icons.inbox_outlined, color: Colors.grey.shade400, size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        'Nenhuma oferta disponível no momento',
                        style: TextStyle(color: Colors.grey, fontSize: 15),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Volte mais tarde ou tente outra startup',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ]),
                  ),
                )
              // Renderiza a lista de cards de oferta quando há dados disponíveis
              else
                ListView.separated(
                  shrinkWrap: true,
                  // Desativa o scroll próprio da lista pois ela está dentro de um SingleChildScrollView
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _offers.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final offer = _offers[index];
                    // Extrai e converte o preço de centavos para reais
                    final priceCents = offer['priceCents'] is num ? (offer['priceCents'] as num).toInt() : 0;
                    final pricePerToken = priceCents / 100;
                    // Quantidade de tokens disponíveis nesta oferta
                    final qty = offer['quantity'] is num ? (offer['quantity'] as num).toInt() : 0;
                    // Valor total da oferta em centavos
                    final totalCents = priceCents * qty;
                    final sellerName = offer['sellerName'] as String? ?? 'Vendedor';

                    // Calcula variação em relação ao preço de mercado
                    final marketCents = (widget.tokenPrice * 100).round();
                    final diff = marketCents > 0 ? ((priceCents - marketCents) / marketCents) * 100 : 0.0;
                    // Determina se o preço está significativamente acima ou abaixo do mercado (tolerância de 0.5%)
                    final isAbove = diff > 0.5;
                    final isBelow = diff < -0.5;

                    // Identifica a primeira oferta da lista (menor preço) para destaque visual
                    final bool isFirst = index == 0;

                    // Cada card de oferta é clicável e abre o dialog de confirmação de compra
                    return GestureDetector(
                      onTap: () => _showBuyConfirmation(offer),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          // A melhor oferta recebe borda e fundo diferenciados em verde
                          border: Border.all(
                            color: isFirst ? const Color(0xFF2E7D32) : Colors.grey.shade300,
                            width: isFirst ? 2 : 1,
                          ),
                          color: isFirst ? const Color(0xFFE8F5E9) : Colors.white,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Badge "Melhor oferta" para o primeiro
                                if (isFirst) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2E7D32),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'Melhor oferta',
                                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const Spacer(),
                                ] else
                                  const Spacer(),

                                // Variação vs mercado
                                if (isAbove || isBelow)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      // Laranja para preço acima, azul para preço abaixo do mercado
                                      color: isAbove ? Colors.orange.shade50 : Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${isAbove ? '+' : ''}${diff.toStringAsFixed(1)}% ${isAbove ? 'acima' : 'abaixo'} do mercado',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isAbove ? Colors.orange.shade700 : Colors.blue.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Preço unitário do token em destaque
                                      Text(
                                        _formatMoney(pricePerToken),
                                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                                      ),
                                      Text(
                                        'por token',
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    // Quantidade de tokens disponíveis nesta oferta
                                    Text(
                                      '$qty tokens disponíveis',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    // Valor total caso o comprador adquira todos os tokens da oferta
                                    Text(
                                      'Total: ${_formatMoney(totalCents / 100)}',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Exibe o nome do vendedor com ícone de pessoa
                                Row(children: [
                                  SvgPicture.asset(
                                    'assets/icons/person.svg',
                                    colorFilter: ColorFilter.mode(Colors.grey.shade500, BlendMode.srcIn),
                                    width: 14,
                                    height: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(sellerName, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                ]),
                                // Botão de ação principal para iniciar o fluxo de compra
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2E7D32),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Comprar',
                                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Exibe o dialog de confirmação de compra para uma oferta específica
  void _showBuyConfirmation(Map<String, dynamic> offer) {
    // Extrai os dados da oferta selecionada
    final priceCents = offer['priceCents'] is num ? (offer['priceCents'] as num).toInt() : 0;
    final pricePerToken = priceCents / 100;
    final qty = offer['quantity'] is num ? (offer['quantity'] as num).toInt() : 0;
    final offerId = offer['id'] as String? ?? '';

    // Quantidade fixa — compra o anúncio todo
    int buyQty = qty;
    final senhaController = TextEditingController();
    // Controla a visibilidade da senha no campo de texto
    bool senhaVisivel = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        // Mensagem de erro exibida dentro do dialog
        String? erro;
        // Controla o estado de loading do botão de confirmar
        bool loading = false;
        // StatefulBuilder permite atualizar o estado interno do dialog sem reconstruir a tela toda
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            // Calcula o valor total com base na quantidade e preço por token
            final totalValue = buyQty * pricePerToken;
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Confirmar compra', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),

                      // Resumo da oferta
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Nome da startup vinculada à oferta
                            Text(widget.startupName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            // Preço unitário do token desta oferta
                            Text(
                              'Preço por token: ${_formatMoney(pricePerToken)}',
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                            // Quantidade total de tokens que serão adquiridos
                            Text(
                              'Disponível: $qty tokens',
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Quantidade (fixa — compra o anúncio todo)
                      const Text('Quantidade', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      // Campo não editável que exibe a quantidade fixa da oferta
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.shade100,
                        ),
                        child: Text('$qty tokens', style: const TextStyle(fontSize: 16)),
                      ),
                      const SizedBox(height: 12),

                      // Total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total a pagar:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          // Valor total calculado em destaque
                          Text(
                            _formatMoney(totalValue),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      const Text('Digite sua senha para confirmar', style: TextStyle(color: Colors.grey, fontSize: 14)),
                      const SizedBox(height: 10),
                      // Exibe o container de erro apenas se houver mensagem de erro
                      if (erro != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Text(erro!, style: const TextStyle(color: Color(0xFFB30B0E), fontSize: 13)),
                        ),
                      // Campo de senha com toggle de visibilidade e ícone SVG customizado
                      TextField(
                        controller: senhaController,
                        obscureText: !senhaVisivel,
                        enabled: !loading,
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          prefixIcon: Padding(
                            padding: EdgeInsets.all(12),
                            child: SvgPicture.asset(
                              'assets/icons/password.svg',
                              colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          // Desabilita o botão durante o loading ou se a quantidade for inválida
                          onPressed: (loading || buyQty <= 0) ? null : () async {
                            if (senhaController.text.isEmpty) {
                              setDialogState(() => erro = 'Informe sua senha');
                              return;
                            }
                            setDialogState(() { loading = true; erro = null; });
                            try {
                              // Reautentica o usuário antes de executar a transação financeira
                              final user = FirebaseAuth.instance.currentUser!;
                              await user.reauthenticateWithCredential(
                                EmailAuthProvider.credential(email: user.email!, password: senhaController.text),
                              );
                              // Chama a Cloud Function para aceitar a oferta e registrar a compra
                              final callable = FirebaseFunctions.instance.httpsCallable('acceptOffer');
                              await callable.call({
                                'offerId': offerId,
                                'quantity': buyQty,
                              });
                              // Fecha o dialog e exibe a confirmação de sucesso na tela anterior
                              if (dialogContext.mounted) Navigator.pop(dialogContext);
                              await Future.delayed(const Duration(milliseconds: 100));
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Compra realizada! $buyQty tokens de ${widget.startupName}'),
                                    backgroundColor: const Color(0xFF2E7D32),
                                  ),
                                );
                                Navigator.pop(context);
                              }
                            } on FirebaseAuthException catch (_) {
                              // Senha incorreta: exibe o erro sem fechar o dialog
                              setDialogState(() { erro = 'Senha incorreta'; loading = false; });
                            } on FirebaseFunctionsException catch (e) {
                              // Fecha o dialog antes de exibir o feedback de erro via SnackBar
                              if (dialogContext.mounted) Navigator.pop(dialogContext);
                              await Future.delayed(const Duration(milliseconds: 100));
                              if (mounted) {
                                // Redireciona para o dialog de saldo insuficiente se for esse o motivo do erro
                                if (e.code == 'failed-precondition' || (e.message ?? '').toLowerCase().contains('saldo')) {
                                  _showInsuficiente();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.message ?? 'Erro na compra'), backgroundColor: Color(0xFFB30B0E)),
                                  );
                                }
                              }
                            } catch (_) {
                              // Captura erros inesperados sem travar a interface
                              setDialogState(() { erro = 'Erro inesperado'; loading = false; });
                            }
                          },
                          // Exibe spinner durante o processamento ou o texto do botão quando disponível
                          child: loading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Confirmar compra', style: TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Exibe um dialog informando que o saldo é insuficiente para a compra
  void _showInsuficiente() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Saldo insuficiente', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Você não possui saldo suficiente para esta compra. Adicione saldo na sua carteira.'),
        actions: [
          // Fecha o dialog e retorna para a tela anterior ao clicar em Voltar
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: const Text('Voltar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
