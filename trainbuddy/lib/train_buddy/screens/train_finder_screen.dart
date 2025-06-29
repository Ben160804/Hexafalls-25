import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/train_finder_controller.dart';
import '../models/station.dart';

class TrainFinderScreen extends StatelessWidget {
  const TrainFinderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TrainFinderController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Trains'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStationInputField(
              controller: controller,
              nameController: controller.sourceNameController,
              codeController: controller.sourceCodeController,
              label: 'Source Station',
              hint: 'e.g., Sealdah',
              icon: Icons.location_on,
              suggestions: controller.sourceSuggestions,
              onSuggestionSelected: controller.selectSourceStation,
            ),
            const SizedBox(height: 16),
            _buildStationInputField(
              controller: controller,
              nameController: controller.destinationNameController,
              codeController: controller.destinationCodeController,
              label: 'Destination Station',
              hint: 'e.g., Berhampure Court',
              icon: Icons.location_on,
              suggestions: controller.destinationSuggestions,
              onSuggestionSelected: controller.selectDestinationStation,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: controller.dateController,
              label: 'Journey Date',
              hint: 'YYYYMMDD (e.g., 20250521)',
              icon: Icons.calendar_today,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            Obx(() {
              if (controller.errorMessage.value != null) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    controller.errorMessage.value!,
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
            Obx(() => ElevatedButton(
              onPressed: controller.isLoading.value
                  ? null
                  : controller.searchTrains,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: controller.isLoading.value
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Search Trains',
                      style: TextStyle(fontSize: 16),
                    ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildStationInputField({
    required TrainFinderController controller,
    required TextEditingController nameController,
    required TextEditingController codeController,
    required String label,
    required String hint,
    required IconData icon,
    required RxList<Station> suggestions,
    required Function(Station) onSuggestionSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              prefixIcon: Icon(icon),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade300),
              ),
            ),
          ),
        ),
        Obx(() {
          if (suggestions.isEmpty) return const SizedBox.shrink();
          return Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                final station = suggestions[index];
                return ListTile(
                  title: Text(station.name),
                  subtitle: Text(station.code),
                  onTap: () => onSuggestionSelected(station),
                );
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade300),
          ),
        ),
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
      ),
    );
  }
}
