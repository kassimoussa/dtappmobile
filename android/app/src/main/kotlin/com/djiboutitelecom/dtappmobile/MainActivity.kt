package com.djiboutitelecom.dtappmobile

import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    // Le sélecteur d'applications récentes affiche une capture de l'écran : solde,
    // numéros, reçus. On la masque sans interdire les captures d'écran faites par
    // l'utilisateur, qui partage parfois un reçu ou un écran au support.
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            // Android 13+ : réglage prévu pour cela, sans effet sur les captures.
            setRecentsScreenshotEnabled(false)
        }
    }

    // Avant Android 13 : FLAG_SECURE posé quand l'app quitte le premier plan (la
    // capture des récents est prise juste après) et retiré à son retour. Au
    // mieux : le moment exact de la capture dépend du constructeur.
    override fun onPause() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            window.setFlags(
                WindowManager.LayoutParams.FLAG_SECURE,
                WindowManager.LayoutParams.FLAG_SECURE,
            )
        }
        super.onPause()
    }

    override fun onResume() {
        super.onResume()
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
        }
    }
}
