import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/pet_model.dart';

class AdoptionContractScreen extends StatefulWidget {
  final PetModel pet;

  const AdoptionContractScreen({
    super.key,
    required this.pet,
  });

  @override
  State<AdoptionContractScreen> createState() => _AdoptionContractScreenState();
}

class _AdoptionContractScreenState extends State<AdoptionContractScreen> {
  bool _clauseCare = true;
  bool _clauseNoAbandon = true;
  bool _clauseNeutering = true;
  bool _clauseFollowUp = true;
  bool _isSigned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contrato de Adopción Responsable'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Cabecera institucional
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.gavel, color: AppTheme.primaryColor, size: 36),
                      const SizedBox(height: 8),
                      const Text(
                        'Acuerdo de Compromiso y Tenencia Responsable',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'PetMatch • Plataforma de Protección Animal',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Ficha del animal a adoptar
                const Text('Datos del Animal en Adopción', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  color: Colors.grey[100],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• Mascota: ${widget.pet.name} (${widget.pet.breed})', style: const TextStyle(fontSize: 14)),
                        const SizedBox(height: 4),
                        Text('• Sexo: ${widget.pet.genderBadgeText} • Edad: ${widget.pet.ageFormatted}', style: const TextStyle(fontSize: 14)),
                        const SizedBox(height: 4),
                        Text('• Estado Reproductivo: ${widget.pet.reproductiveBadgeText}', style: const TextStyle(fontSize: 14)),
                        const SizedBox(height: 4),
                        Text('• Microchip: ${widget.pet.hasMicrochip ? 'Sí (Registrado)' : 'No colocado'}', style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Cláusulas legales
                const Text('Cláusulas y Términos Legales', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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

                const SizedBox(height: 24),

                if (_isSigned) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green[300]!),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.verified_user, color: AppTheme.successGreen, size: 28),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '¡Contrato Firmado Digitalmente!',
                                style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.successGreen),
                              ),
                              Text(
                                'Hash de validez registrado. Copia enviada al correo de ambas partes.',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    icon: const Icon(Icons.draw),
                    label: const Text('Firmar y Aceptar Contrato de Adopción'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: (_clauseCare && _clauseNoAbandon && _clauseNeutering && _clauseFollowUp)
                        ? () {
                            setState(() => _isSigned = true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Contrato de adopción formalizado con éxito.'),
                                backgroundColor: AppTheme.successGreen,
                              ),
                            );
                          }
                        : null,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClauseTile(String title, String description, bool value, ValueChanged<bool?> onChanged) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(description, style: const TextStyle(fontSize: 12, color: Colors.black87)),
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.primaryColor,
    );
  }
}
