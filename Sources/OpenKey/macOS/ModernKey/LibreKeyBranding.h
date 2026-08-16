//
//  LibreKeyBranding.h
//  LibreKey
//
//  Every fork-specific name, identifier and URL lives here so rebranding is one
//  file rather than a string hunt across the codebase.
//
//  LibreKey is a fork of OpenKey (https://github.com/tuyenvm/OpenKey) by Tuyen Mai.
//  The engine under Sources/OpenKey/engine is unchanged.
//

#ifndef LibreKeyBranding_h
#define LibreKeyBranding_h

//Must differ from com.tuyenmai.openkey. macOS keys Accessibility grants,
//LaunchServices registration and login items on the bundle identifier, so
//sharing one with the upstream app makes the two installs fight.
#define LIBREKEY_BUNDLE              @"vn.viethoavnm.librekey"
#define LIBREKEY_HELPER_BUNDLE       @"vn.viethoavnm.librekey.Helper"

//Folder under ~/Library/Application Support. NSUserDomainMask already scopes
//this per mac user; the single-instance lock lives inside it.
#define LIBREKEY_SUPPORT_FOLDER      @"LibreKey"

#endif /* LibreKeyBranding_h */
