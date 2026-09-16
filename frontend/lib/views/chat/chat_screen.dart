import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/pet_model.dart';
import '../contract/adoption_contract_screen.dart';

class ChatMessage {
  final String id;
  final String text;
  final bool isMe;
  final DateTime time;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isMe,
    required this.time,
    this.isRead = true,
  });
}

class ChatScreen extends StatefulWidget {
  final PetModel pet;
  final String shelterName;

  const ChatScreen({
    super.key,
    required this.pet,
    this.shelterName = 'Refugio Patitas Felices',
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late List<ChatMessage> _messages;

  @override
  void initState() {
    super.initState();
    _messages = [
      ChatMessage(
        id: '1',
        text: '¡Hola! Vimos tu formulario de adopción para ${widget.pet.name} y nos pareció excelente tu perfil.',
        isMe: false,
        time: DateTime.now().subtract(const Duration(minutes: 45)),
      ),
      ChatMessage(
        id: '2',
        text: 'Notamos que tienes un departamento con red en las ventanas, lo cual es perfecto para su seguridad.',
        isMe: false,
        time: DateTime.now().subtract(const Duration(minutes: 42)),
      ),
      ChatMessage(
        id: '3',
        text: '¡Hola! Qué alegría recibir esta noticia. Estoy muy interesado/a y listo/a para coordinar.',
        isMe: true,
        time: DateTime.now().subtract(const Duration(minutes: 25)),
      ),
      ChatMessage(
        id: '4',
        text: '¿Te parece si agendamos una llamada o visita este fin de semana para que conozcas a ${widget.pet.name} en persona?',
        isMe: false,
        time: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
    ];
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: text,
          isMe: true,
          time: DateTime.now(),
        ),
      );
      _textController.clear();
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(
                widget.pet.photos.isNotEmpty
                    ? widget.pet.photos.first
                    : 'https://images.unsplash.com/photo-1548767797-d8c844163c4c?auto=format&fit=crop&w=800&q=80',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.pet.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    widget.shelterName,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Ver Contrato de Adopción',
            icon: const Icon(Icons.description_outlined, color: AppTheme.primaryColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdoptionContractScreen(pet: widget.pet),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Agendar Visita',
            icon: const Icon(Icons.event_available_outlined, color: AppTheme.textDark),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Propuesta de visita enviada para este Sábado 16:00 hs.'),
                  backgroundColor: AppTheme.successGreen,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner de estado de postulación
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.green[50],
            child: Row(
              children: [
                const Icon(Icons.verified, color: AppTheme.successGreen, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '¡Match Aprobado! Puedes coordinar la visita y revisar el contrato de adopción.',
                    style: TextStyle(fontSize: 12, color: Colors.green[900], fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          // Lista de Mensajes
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),

          // Caja de texto inferior
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: const Offset(0, -2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.camera_alt_outlined, color: AppTheme.textMuted),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Adjuntar foto de la vivienda...')),
                      );
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppTheme.primaryColor,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 18),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: msg.isMe ? AppTheme.primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(msg.isMe ? 18 : 4),
            bottomRight: Radius.circular(msg.isMe ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: TextStyle(
                color: msg.isMe ? Colors.white : AppTheme.textDark,
                fontSize: 14,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${msg.time.hour.toString().padLeft(2, '0')}:${msg.time.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: msg.isMe ? Colors.white70 : Colors.black45,
                    fontSize: 10,
                  ),
                ),
                if (msg.isMe) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.done_all, size: 12, color: Colors.white70),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
