// lib/models/topup_balance_real.dart
import 'package:flutter/material.dart';
import 'topup_balance.dart';

// Modèle pour la réponse réelle de l'API TopUp (format actuel)
class TopUpRealBalanceResponse {
  final String solde;
  final String soldeFormate;
  final String dateSupervision;
  final String dateServiceFee;
  final String dateCreditClearance;
  final String dateServiceRemoval;
  final int codeReponse;
  final String messageReponse;
  final List<CompteDedie> comptesDedies;

  TopUpRealBalanceResponse({
    required this.solde,
    required this.soldeFormate,
    required this.dateSupervision,
    required this.dateServiceFee,
    required this.dateCreditClearance,
    required this.dateServiceRemoval,
    required this.codeReponse,
    required this.messageReponse,
    required this.comptesDedies,
  });

  factory TopUpRealBalanceResponse.fromJson(Map<String, dynamic> json) {
    return TopUpRealBalanceResponse(
      solde: json['solde'] ?? '0',
      soldeFormate: json['solde_formate'] ?? '0.00 DJF',
      dateSupervision: json['date_supervision'] ?? '',
      dateServiceFee: json['date_service_fee'] ?? '',
      dateCreditClearance: json['date_credit_clearance'] ?? '',
      dateServiceRemoval: json['date_service_removal'] ?? '',
      codeReponse: json['code_reponse'] ?? 1,
      messageReponse: json['message_reponse'] ?? '',
      comptesDedies: (json['comptes_dedies'] as List<dynamic>?)
          ?.map((item) => CompteDedie.fromJson(item))
          .toList() ?? [],
    );
  }

  // Convertir vers le format attendu par l'UI
  TopUpBalanceResponse toStandardFormat(String msisdn, String isdn) {
    final balances = <TopUpBalance>[];
    
    // Ajouter le solde principal
    if (solde.isNotEmpty && solde != '0') {
      balances.add(TopUpBalance(
        name: 'Solde Principal',
        type: 'money',
        value: double.tryParse(solde) ?? 0.0,
        formattedValue: soldeFormate,
        unit: 'DJF',
        expireDate: dateServiceRemoval,
        expireDateFormatted: _formatDate(dateServiceRemoval),
        expirationStatus: TopUpExpirationStatus(
          status: 'active',
          priority: 0,
          message: 'Expire le ${_formatDate(dateServiceRemoval)}',
        ),
        rawType: 'MAIN_BALANCE',
      ));
    }
    
    // Ajouter les comptes dédiés non-vides
    for (final compte in comptesDedies) {
      if (compte.valeur > 0) {
        balances.add(TopUpBalance(
          name: _getCompteTypeName(compte.typeDescription, compte.id),
          type: _mapCompteType(compte.typeDescription),
          value: compte.valeur.toDouble(),
          formattedValue: compte.valeurFormatee,
          unit: _getCompteUnit(compte.typeDescription),
          expireDate: compte.dateExpiration == 'Illimitée' ? dateServiceRemoval : compte.dateExpiration,
          expireDateFormatted: compte.dateExpiration == 'Illimitée' 
              ? _formatDate(dateServiceRemoval) 
              : _formatDate(compte.dateExpiration),
          expirationStatus: TopUpExpirationStatus(
            status: compte.dateExpiration == 'Illimitée' ? 'active' : 'warning',
            priority: compte.dateExpiration == 'Illimitée' ? 0 : 1,
            message: compte.dateExpiration == 'Illimitée' 
                ? 'Pas d\'expiration' 
                : 'Expire le ${_formatDate(compte.dateExpiration)}',
          ),
          rawType: 'DEDICATED_ACCOUNT_${compte.id}',
        ));
      }
    }
    
    // Calculer le résumé
    double moneyTotal = 0;
    int dataTotal = 0;
    int voiceTotal = 0;
    
    for (final balance in balances) {
      switch (balance.type) {
        case 'money':
          moneyTotal += balance.value;
          break;
        case 'data':
          dataTotal += balance.value.toInt();
          break;
        case 'voice':
          voiceTotal += balance.value.toInt();
          break;
      }
    }
    
    final summary = TopUpBalanceSummary(
      totalBalances: balances.length,
      moneyTotal: moneyTotal,
      moneyTotalFormatted: '${moneyTotal.toStringAsFixed(2)} DJF',
      dataTotalBytes: dataTotal,
      dataTotalFormatted: _formatDataBytes(dataTotal),
      voiceTotalSeconds: voiceTotal,
      voiceTotalFormatted: _formatVoiceSeconds(voiceTotal),
    );
    
    final details = TopUpBalanceDetails(
      mobileMsisdn: msisdn,
      fixedIsdn: isdn,
      requestTime: DateTime.now().toIso8601String(),
      totalBalances: balances.length,
      backendApi: 'TopUp Real API',
    );
    
    return TopUpBalanceResponse(
      success: codeReponse == 0,
      message: messageReponse,
      mobileMsisdn: msisdn,
      fixedIsdn: isdn,
      balances: balances,
      totalBalances: balances.length,
      summary: summary,
      details: details,
    );
  }

  String _getCompteTypeName(String typeDescription, int id) {
    switch (typeDescription) {
      case 'time':
        return 'Minutes d\'appel';
      case 'money':
        return 'Crédit bonus';
      case 'volume':
        return 'Données Internet';
      default:
        return 'Compte dédié $id';
    }
  }

  String _mapCompteType(String typeDescription) {
    switch (typeDescription) {
      case 'time':
        return 'voice';
      case 'money':
        return 'money';
      case 'volume':
        return 'data';
      default:
        return 'unknown';
    }
  }

  String _getCompteUnit(String typeDescription) {
    switch (typeDescription) {
      case 'time':
        return 'seconds';
      case 'money':
        return 'DJF';
      case 'volume':
        return 'bytes';
      default:
        return 'units';
    }
  }

  String _formatDate(String dateString) {
    try {
      if (dateString.isEmpty || dateString == 'Illimitée') {
        return 'Pas d\'expiration';
      }
      
      // Format: "19/08/2026" ou "09/08/2025"
      final parts = dateString.split('/');
      if (parts.length == 3) {
        return '${parts[0]}/${parts[1]}/${parts[2]}';
      }
      return dateString;
    } catch (e) {
      return dateString;
    }
  }

  String _formatDataBytes(int bytes) {
    if (bytes == 0) return '0 Mo';
    if (bytes < 1024) return '$bytes o';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} Ko';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} Go';
  }

  String _formatVoiceSeconds(int seconds) {
    if (seconds == 0) return '0 sec';
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }
}

class CompteDedie {
  final int id;
  final int valeur;
  final int valeurActive;
  final int typeUnite;
  final String typeDescription;
  final String dateExpiration;
  final String valeurFormatee;

  CompteDedie({
    required this.id,
    required this.valeur,
    required this.valeurActive,
    required this.typeUnite,
    required this.typeDescription,
    required this.dateExpiration,
    required this.valeurFormatee,
  });

  factory CompteDedie.fromJson(Map<String, dynamic> json) {
    return CompteDedie(
      id: json['id'] ?? 0,
      valeur: json['valeur'] is String 
          ? int.tryParse(json['valeur']) ?? 0 
          : json['valeur'] ?? 0,
      valeurActive: json['valeur_active'] is String 
          ? int.tryParse(json['valeur_active']) ?? 0 
          : json['valeur_active'] ?? 0,
      typeUnite: json['type_unite'] ?? 0,
      typeDescription: json['type_description'] ?? '',
      dateExpiration: json['date_expiration'] ?? '',
      valeurFormatee: json['valeur_formatee'] ?? '',
    );
  }
}

