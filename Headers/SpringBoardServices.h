// Función privada de SpringBoardServices.framework usada desde procesos
// que no son SpringBoard (como Preferences) para obtener el PNG del
// icono de cualquier app instalada a partir de su bundle identifier.
// Es la técnica estándar que usan tweaks como AppList para mostrar
// iconos de apps fuera de SpringBoard.

#import <Foundation/Foundation.h>

CFDataRef SBSCopyIconImagePNGDataForDisplayIdentifier(CFStringRef displayIdentifier, int format);
