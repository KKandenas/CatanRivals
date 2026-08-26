// Egen bootstrap-mall i stället för den auto-genererade (se
// https://github.com/flutter/flutter/issues/156910 – "Loading the
// service worker using Flutter bootstrap is deprecated") – utelämnar
// MEDVETET `serviceWorkerSettings` nedan så att appen aldrig
// registrerar någon service worker alls.
//
// Bakgrund: en hemskärmssparad PWA (iOS) hängde konsekvent på samma
// sätt vid varje laddning ("fastnar på sista bilden"), trots en full
// omstart av appen – bara en helt ny hemskärmsikon hjälpte, och bara
// tillfälligt (nästa laddning hängde igen). En vanlig Safari-flik med
// exakt samma adress fungerade hela tiden. Det mönstret pekar exakt på
// en fastnad, cachad service worker (index.html:s städskript rensar
// bort en redan installerad sådan från en äldre version, men UTAN att
// sluta registrera nya skulle appen kunna hamna i samma fälla igen).
// Utan en service worker gör varje sidladdning en riktig nätverksfetch
// (vanlig HTTP-cachning från GitHub Pages gäller fortfarande) – ingen
// offline-cachning, men appen kräver ändå nätverk för allt utom "spela
// lokalt", och det är ett litet pris för att slippa hela den här
// bugg­klassen.
{{flutter_js}}
{{flutter_build_config}}
_flutter.loader.load({
  config: { canvasKitBaseUrl: "canvaskit/" },
});
