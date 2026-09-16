import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/services/api_service.dart';
import '../../models/match_model.dart';

class AdoptionContractScreen extends StatefulWidget {
  final MatchModel match;

  const AdoptionContractScreen({super.key, required this.match});

  @override
  State<AdoptionContractScreen> createState() => _AdoptionContractScreenState();
}

class _AdoptionContractScreenState extends State<AdoptionContractScreen> {
  final ApiService _api = ApiService();

  bool _clauseCare = true;
  bool _clauseNoAbandon = true;
  bool _clauseNeutering = true;
  bool _clauseFollowUp = true;

  bool _isLoading = true;
  bool _isSubmitting = false;
  Map<String, dynamic>? _contract;

  String? get _currentUserId => Supabase.instance.client.auth.currentUser?.id;
  bool get _isShelter => _currentUserId == widget.match.shelterId;

  bool get _signedByAdopter => _contract?['signed_by_adopter'] == true;
  bool get _signedByShelter => _contract?['signed_by_shelter'] == true;
  bool get _iAlreadySigned => _isShelter ? _signedByShelter : _signedByAdopter;
  bool get _fullySigned => _signedByAdopter && _signedByShelter;

  @override
  void initState() {
    super.initState();
    _loadContract();
  }

  Future<void> _loadContract() async {
    try {
      final data = await _api.get('/contracts/${widget.match.id}');
      if (!mounted) return;
      setState(() {
        _contract = data as Map<String, dynamic>?;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createContract() async {
    setState(() => _isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final data = await _api.post('/contracts/${widget.match.id}');
      if (!mounted) return;
      setState(() {
        _contract = data as Map<String, dynamic>?;
        _isSubmitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      messenger.showSnackBar(
        SnackBar(content: Text('No se pudo generar el contrato: $e')),
      );
    }
  }

  Future<void> _signContract() async {
    setState(() => _isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final data = await _api.post('/contracts/${widget.match.id}/sign');
      if (!mounted) return;
      setState(() {
        _contract = data as Map<String, dynamic>?;
        _isSubmitting = false;
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _fullySigned
                ? 'Contrato firmado por ambas partes. ¡Adopción formalizada!'
                : 'Firmaste el contrato. Falta la firma de la otra parte.',
          ),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      messenger.showSnackBar(
        SnackBar(content: Text('No se pudo firmar el contrato: $e')),
      );
    }
  }

  bool get _allClausesChecked =>
      _clauseCare && _clauseNoAbandon && _clauseNeutering && _clauseFollowUp;

  @override
  Widget build(BuildContext context) {
    final pet = widget.match.pet;

    return Scaffold(
      appBar: AppBar(title: const Text('Contrato de Adopción Responsable')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 650),
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.gavel,
                              color: AppTheme.primaryColor,
                              size: 36,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Acuerdo de Compromiso y Tenencia Responsable',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'PetMatch • Plataforma de Protección Animal',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Datos del Animal en Adopción',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        elevation: 0,
                        color: Colors.grey[100],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• Mascota: ${pet?.name ?? '-'} (${pet?.breed ?? '-'})',
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '• Sexo: ${pet?.genderBadgeText ?? '-'} • Edad: ${pet?.ageFormatted ?? '-'}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '• Estado Reproductivo: ${pet?.reproductiveBadgeText ?? '-'}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '• Microchip: ${pet?.hasMicrochip == true ? 'Sí (Registrado)' : 'No colocado'}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (_contract == null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.amber[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.amber[300]!),
                          ),
                          child: Text(
                            _isShelter
                                ? 'Todavía no generaste el contrato para esta adopción.'
                                : 'El refugio/publicador aún no generó el contrato de adopción.',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        if (_isShelter) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.note_add_outlined),
                            label: const Text('Generar Contrato de Adopción'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: _isSubmitting ? null : _createContract,
                          ),
                        ],
                      ] else ...[
                        const Text(
                          'Cláusulas y Términos Legales',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildClauseTile(
                          '1. Bienestar y Cuidados Médicos',
                          'El adoptante se compromete a brindar alimento de calidad, agua fresca, abrigo digno y atención veterinaria preventiva y de emergencia durante toda la vida del animal.',
                          _clauseCare,
                          (val) => setState(() => _clauseCare = val!),
                        ),
                        _buildClauseTile(
                          '2. Prohibición de Venta y No Abandono',
                          'Queda terminantemente prohibida la comercialización, reventa, cesión a terceros sin previo aviso o abandono del animal. En caso de no poder mantenerlo, deberá restituirse al dador.',
                          _clauseNoAbandon,
                          (val) => setState(() => _clauseNoAbandon = val!),
                        ),
                        _buildClauseTile(
                          '3. Esterilización Obligatoria',
                          'Si el animal es entregado en edad temprana con compromiso de castración, el adoptante asume la obligación indelegable de esterilizarlo a partir de los 6 meses de vida.',
                          _clauseNeutering,
                          (val) => setState(() => _clauseNeutering = val!),
                        ),
                        _buildClauseTile(
                          '4. Visitas y Seguimiento',
                          'El adoptante acepta mantener comunicación periódica con el dador, enviando fotografías del estado del animal y permitiendo visitas concertadas si fuera necesario.',
                          _clauseFollowUp,
                          (val) => setState(() => _clauseFollowUp = val!),
                        ),
                        const SizedBox(height: 12),
                        _buildSignatureStatus('Adoptante', _signedByAdopter),
                        _buildSignatureStatus(
                          'Refugio / Publicador',
                          _signedByShelter,
                        ),
                        const SizedBox(height: 12),

                        if (_fullySigned) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.green[300]!),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.verified_user,
                                  color: AppTheme.successGreen,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '¡Contrato Firmado Digitalmente!',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.successGreen,
                                        ),
                                      ),
                                      Text(
                                        'Hash de validez: ${(_contract?['signature_hash'] as String?)?.substring(0, 16) ?? ''}…',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else if (_iAlreadySigned) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Text(
                              'Ya firmaste. Esperando la firma de la otra parte para formalizar la adopción.',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ] else ...[
                          ElevatedButton.icon(
                            icon: const Icon(Icons.draw),
                            label: Text(
                              _isSubmitting
                                  ? 'Firmando...'
                                  : 'Firmar y Aceptar Contrato de Adopción',
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: (_allClausesChecked && !_isSubmitting)
                                ? _signContract
                                : null,
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSignatureStatus(String label, bool signed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            signed ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: signed ? AppTheme.successGreen : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ${signed ? 'Firmado' : 'Pendiente'}',
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildClauseTile(
    String title,
    String description,
    bool value,
    ValueChanged<bool?> onChanged,
  ) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Text(
        description,
        style: const TextStyle(fontSize: 12, color: Colors.black87),
      ),
      value: value,
      onChanged: _iAlreadySigned ? null : onChanged,
      activeColor: AppTheme.primaryColor,
    );
  }
}
