import 'package:flutter/material.dart';
import '../api_endpoints.dart';
import 'package:http/http.dart' as http;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _urlController = TextEditingController();
  bool _isTesting = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    _urlController.text = ApiEndpoints.baseUrl;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    try {
      final url = _urlController.text.trim();
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 5),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        setState(() {
          _testResult = '✅ Conexión exitosa (${response.statusCode})';
        });
      } else {
        setState(() {
          _testResult = '⚠️ Servidor respondió con código ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _testResult = '❌ Error de conexión: $e';
      });
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  Future<void> _saveUrl() async {
    final url = _urlController.text.trim();

    if (url.isEmpty) {
      _showSnackBar('Por favor ingresa una URL');
      return;
    }

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      _showSnackBar('La URL debe comenzar con http:// o https://');
      return;
    }

    await ApiEndpoints.setManualUrl(url);
    _showSnackBar('✅ Configuración guardada');
  }

  Future<void> _resetConfiguration() async {
    await ApiEndpoints.resetConfiguration();
    await ApiEndpoints.initializeAsync();
    setState(() {
      _urlController.text = ApiEndpoints.baseUrl;
      _testResult = null;
    });
    _showSnackBar('🔄 Configuración reseteada y servidor re-detectado');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Servidor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Re-detectar servidor',
            onPressed: _resetConfiguration,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // URL actual
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'URL Actual del Servidor',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      ApiEndpoints.baseUrl,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Voice API: ${ApiEndpoints.voiceApiUrl}',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Configuración manual
            const Text(
              'Configurar Manualmente',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'URL del Servidor',
                hintText: 'http://192.168.18.5:5000',
                prefixIcon: Icon(Icons.link),
                border: OutlineInputBorder(),
                helperText: 'Ejemplo: http://192.168.1.100:5000',
              ),
              keyboardType: TextInputType.url,
            ),

            const SizedBox(height: 16),

            // Botones
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isTesting ? null : _testConnection,
                    icon: _isTesting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi_find),
                    label: Text(_isTesting ? 'Probando...' : 'Probar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveUrl,
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Resultado del test
            if (_testResult != null)
              Card(
                color: _testResult!.startsWith('✅')
                    ? Colors.green[50]
                    : Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    _testResult!,
                    style: TextStyle(
                      color: _testResult!.startsWith('✅')
                          ? Colors.green[900]
                          : Colors.red[900],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Ayuda
            Card(
              color: Colors.blue[50],
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.help_outline, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Cómo obtener tu IP',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text('1. Abre PowerShell o CMD en tu PC'),
                    SizedBox(height: 6),
                    Text('2. Ejecuta: ipconfig'),
                    SizedBox(height: 6),
                    Text('3. Busca "Dirección IPv4"'),
                    SizedBox(height: 6),
                    Text('4. Usa esa IP con puerto 5000'),
                    SizedBox(height: 6),
                    Text(
                      'Ejemplo: http://192.168.18.5:5000',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
