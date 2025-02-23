//
//  Entitlements.swift
//  PlayCover
//

import Foundation

class Entitlements {
    
    static var playCoverEntitlementsDir : URL {
        let entFodler = PlayTools.playCoverContainer.appendingPathComponent("Entitlements")
        if !fm.fileExists(atPath: entFodler.path) {
            do {
                try fm.createDirectory(at: entFodler, withIntermediateDirectories: true, attributes: [:])
            } catch{
                Log.shared.error(error)
            }
            
        }
        return entFodler
    }
    
    static func dumpEntitlements(exec : URL) throws -> [String : Any] {
        let result = try Dictionary<String,Any>.read(try copyEntitlements(exec: exec))
        return result ?? [:]
    }
    
    static func areEntitlementsValid(app : PlayApp) throws -> Bool {
        let old = try dumpEntitlements(exec : app.executable)
        let nw = try composeEntitlements(app)
        return (nw as! Dictionary<String, AnyHashable>).hashValue == (old as! Dictionary<String, AnyHashable>).hashValue
    }
    
    static func composeEntitlements(_ app : PlayApp) throws -> [String : Any] {
        
        var base = [String : Any]()
        
        if !app.info.bundleIdentifier.elementsEqual("com.devsisters.ck") {
            base["com.apple.security.app-sandbox"] = true
        }
    
        base["com.apple.security.assets.movies.read-write"] = true
        base["com.apple.security.assets.music.read-write"] = true
        base["com.apple.security.assets.pictures.read-write"] = true
        base["com.apple.security.device.audio-input"] = true
        base["com.apple.security.network.client"] = true
        base["com.apple.security.network.server"] = true
        base["com.apple.security.device.bluetooth"] = true
        base["com.apple.security.device.camera"] = true
        base["com.apple.security.device.usb"] = true
        base["com.apple.security.files.downloads.read-write"] = true
        base["com.apple.security.files.user-selected.read-write"] = true
        base["com.apple.security.network.client"] = true
        base["com.apple.security.network.server"] = true
        base["com.apple.security.personal-information.addressbook"] = true
        base["com.apple.security.personal-information.calendars"] = true
        base["com.apple.security.personal-information.location"] = true
        base["com.apple.security.print"] = true
        
        if SystemConfig.isPlaySignActive() {
            base["com.apple.private.tcc.allow"] = TCC.split(whereSeparator: \.isNewline)
            
            if let specific = try Dictionary<String,Any>.read(app.entitlements) {
                for key in specific.keys {
                    base[key] = specific[key]
                }
            }
        }
        
        var sandboxProfile = [String]()
        
        sandboxProfile.append(contentsOf : ALWAYS_PROFILE)
        
        if app.settings.bypass {
            
            for file in DENY_READ_FILES.split(whereSeparator: \.isNewline) {
                sandboxProfile.append(
                    """
                     (deny file* file-read* file-read-metadata file-ioctl (literal "\(file)"))
                    """
                )
            }

            for file in ALLOW_READ_FILES.split(whereSeparator: \.isNewline) {
                sandboxProfile.append(
                    """
                     (allow file* file-read* file-read-metadata file-ioctl (literal "\(file)"))
                    """
                )
            }
            
            sandboxProfile.append(contentsOf : BASE_PROFILE)
    
        }
        
        base["com.apple.security.temporary-exception.sbpl"] = sandboxProfile
        
        return base
    }
    
    private static func copyEntitlements(exec: URL) throws -> String {
        var en = try excludeEntitlements(exec: exec)
        if !en.contains("DOCTYPE plist PUBLIC"){
            en = Entitlements.entitlements_template
        }
        return en
    }
    
    private static func excludeEntitlements(exec : URL) throws -> String {
        let from = try PlayTools.fetchEntitlements(exec)
        if let range: Range<String.Index> = from.range(of: "<?xml") {
            return String(from[range.lowerBound...])
        }
        else {
            return Entitlements.entitlements_template
        }
    }
    
    private static let TCC =
    """
    kTCCService
    kTCCServiceAll
    kTCCServiceAddressBook
    kTCCServiceCalendar
    kTCCServiceReminders
    kTCCServiceLiverpool
    kTCCServiceUbiquity
    kTCCServiceShareKit
    kTCCServicePhotos
    kTCCServicePhotosAdd
    kTCCServiceMicrophone
    kTCCServiceCamera
    kTCCServiceMediaLibrary
    kTCCServiceSiri
    kTCCServiceAppleEvents
    kTCCServiceAccessibility
    kTCCServicePostEvent
    kTCCServiceLocation
    kTCCServiceSystemPolicyAllFiles
    kTCCServiceSystemPolicySysAdminFiles
    kTCCServiceSystemPolicyDeveloperFile
    kTCCServiceSystemPolicyDocumentsFolder
    """
    
    private static let ALLOW_READ_FILES =
    """
    /Users/\(NSUserName())/Library/Containers/
    /Users
    /cores
    /usr
    /sbin/mount
    /sbin/launchd
    /sbin
    /etc/passwd
    /dev/null
    /etc/hosts
    /usr/lib/libSystem.B.dylib
    """
    
    private static let DENY_READ_FILES =
        """
        /System/Volumes/Data
        /bin/ls
        /bin/sed
        /bin/kill
        /bin/gzip
        /usr/bin/which
        /usr/bin/diff
        /bin/mkdir
        /bin/cp
        /bin/chgrp
        /bin/cat
        /bin/tar
        /bin/chmod
        /usr/share/terminfo
        /bin/grep
        /bin/chown
        /usr/bin/tar
        /usr/bin/killall
        /bin/ln
        /usr/bin/xargs
        /bin/su
        /usr/bin/recache
        /etc/profile
        /bin/bunzip2
        /usr/bin/passwd
        /etc/apt
        /usr/bin/hostinfo
        /bin/bzip2
        /bin/bash
        /bin/sh
        /bin/mv
        /Library/PreferenceBundles/LaunchInSafeMode.bundle
        /private/var/binpack
        /private/var/lib/apt
        /private/var/stash
        /usr/bin/sshd
        /var/cache/apt
        /var/lib/apt
        /var/lib/cydia
        /usr/sbin/frida-server
        /usr/bin/cycript
        /usr/local/bin/cycript
        /usr/lib/libcycript.dylib
        /var/log/syslog
        /Library/MobileSubstrate/MobileSubstrate.dylib
        /etc/apt
        /usr/libexec/ssh-keysign
        /usr/sbin/sshd
        /etc/ssh/sshd_config
        /usr/libexec/sftp-server
        """
    
    public static func isAppRequireUnsandbox(_ app : PhysicialApp) -> Bool {
        return unsandboxedApps.contains(app.info.bundleIdentifier)
    }
    
    private static let unsandboxedApps = ["com.devsisters.ck"]
    
    static let entitlements_template = """
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
    </dict>
    </plist>
    """
    
    private static let ALWAYS_PROFILE =
    ["""
     (allow user-preference-write
       (preference-domain ".GlobalPreferences"))
     (allow user-preference-read
     (preference-domain ".GlobalPreferences"))
    
    """,
     "(allow file* file-read* file-write* file-write-data file-read-metadata file-ioctl (literal \"/Users/\(NSUserName())/Library/Preferences/playcover.plist\"))",
     "(allow file* file-read* file-read-metadata file-ioctl (literal \"/Users/\(NSUserName())/Library/Frameworks/865DN\"))",
    ]
    private static let BASE_PROFILE = [
                                                "(deny process-fork)",
                                                "(allow file* file-read* file-read-metadata file-ioctl) (literal \"/tmp/cclibraries-ngl-log.cfg\")",
                                                "(deny file* file-read* file-read-metadata file-ioctl)",
                                                "(allow file* file-read* file-read-metadata file-ioctl (literal \"/usr/lib/libobjc-trampolines.dylib\"))",
                                                "(allow file-read-metadata (subpath \"/private/var/db/timezone/\"))",
                                                "(allow file* file-read* file-read-data file-read-metadata file-ioctl file-write* file-write-data (literal \"/var/folders/kd/\"))",
                                                "(allow file* file-read* file-read-metadata file-ioctl (subpath \"/Users/\(NSUserName())/Library/Containers/\"))",
                                                "(allow file* file-read* file-read-metadata file-ioctl (literal \"/usr/share/icu/icudt68l.dat\"))",
                                                "(allow file* file-read* file-read-metadata file-ioctl (literal \"/System/Library/CoreServices/SystemVersion.bundle\"))",
                                                "(allow file* file-read* file-read-metadata file-ioctl (subpath \"/System/\"))",
                                                "(allow file-read-metadata file-ioctl (literal \"/private/var/db/.AppleSetupDone\"))",
                                                "(allow file* file-read* file-read-data file-read-metadata file-ioctl file-write* file-write-data (subpath \"/private/var/folders/kd/\"))",
                                                "(allow file* file-read* file-read-metadata file-ioctl (literal \"/private/var/db/timezone/tz/2021a.3.0/icutz\"))",
                                                "(allow file* file-read* file-read-data file-read-metadata file-ioctl file-write* file-write-data (subpath \"/private/var/folders/kd/\"))",
                                                "(allow file* file-read* file-read-metadata file-ioctl (literal \"/private/var/db/nsurlstoraged/dafsaData.bin\"))",
                                                "(allow file* file-read* file-read-metadata file-ioctl (literal \"/private/var/folders/\"))",
                                                "(allow file* file-read* file-read-metadata file-ioctl (literal \"/Library/Preferences/Logging/com.apple.diagnosticd.filter.plist\"))",
                                                "(allow file* file-read* file-read-metadata file-ioctl (literal \"/Library/Caches/com.apple.iconservices.store\"))",
                                                "(allow file* file-read* file-read-metadata file-ioctl (literal \"/Library/Apple/Library/Bundles/InputAlternatives.bundle\"))",
                                                "(allow file-read* (literal \"/dev/autofs_nowait\") (literal \"/dev/random\") (literal \"/dev/urandom\"))",
                                                "(allow file-read* file-write-data (literal \"/dev/null\") (literal \"/dev/zero\"))",
                                                "(allow file-read-data (regex #\"^/private/var/db/mds/\"))",
                                                "(allow file-ioctl file* file-read* file-read-data file-read-metadata (literal \"/private/var/db/mds/system/mdsObject.db\"))",
                                                "(allow file-read-metadata file-read* file-write* (regex #\"^/private/var/db/mds/[0-9]+(/|$)\"))",
                                                "(allow file-read-data (regex #\"^/Users/[^/]+/Library/Preferences/com.apple.CloudKit.plist\"))",
                                                "(allow file-read-metadata file-read* file-read-data (literal \"/usr/share/langid/langid.inv\"))",
                                                """
                                                (allow file-map-executable
                                                       (subpath "/Library/Apple/System/Library/Frameworks")
                                                       (subpath "/Library/Apple/System/Library/PrivateFrameworks")
                                                       (subpath "/System/Library/Frameworks")
                                                       (subpath "/System/Library/PrivateFrameworks")
                                                       (subpath "/System/iOSSupport/System/Library/Frameworks")
                                                       (subpath "/System/iOSSupport/System/Library/PrivateFrameworks")
                                                       (subpath "/usr/lib"))
                                                (with-filter (system-attribute apple-internal)
                                                  (allow file-map-executable
                                                         (subpath "/AppleInternal/Library/Frameworks")))
                                                """,
                                                """
                                                (allow file-read-metadata
                                                       (literal "/private/etc/localtime"))
                                                """,
                                                """
                                                (allow file-read-metadata (path-ancestors "/System/Volumes/Data/private"))
                                                """,
                                                "(allow file-read* (literal \"/\"))",
                                                """
                                                 (allow file-read*
                                                        (subpath "/Library/Apple/System")
                                                        (subpath "/Library/Filesystems/NetFSPlugins")
                                                        (subpath "/Library/Preferences/Logging")      ; Logging Rethink
                                                        (subpath "/System")
                                                        (subpath "/private/var/db/dyld")
                                                        (subpath "/private/var/db/timezone")
                                                        (subpath "/usr/lib"))
                                                        
                                                 (with-filter (system-attribute apple-internal)
                                                   (allow file-read*
                                                          (subpath "/AppleInternal/Library/Frameworks")))
                                                 """, //(subpath "/usr/share"))
                                                
                                                 """
                                                  (allow file-read*
                                                        (literal "/dev/autofs_nowait")
                                                        (literal "/dev/random")
                                                        (literal "/dev/urandom")
                                                        (literal "/private/etc/master.passwd")
                                                        (literal "/private/etc/passwd")
                                                        (literal "/private/etc/protocols")
                                                        (literal "/private/etc/services"))
                                                  """,
                                                  """
                                                   (allow file-read*
                                                          file-write-data
                                                          file-ioctl
                                                          (literal "/dev/dtracehelper"))
                                                  """,
                                                  """
                                                    (with-filter (system-attribute apple-internal)
                                                      (allow file-read* file-map-executable
                                                             (subpath "/usr/local/lib/sanitizers")
                                                             (subpath "/usr/appleinternal/lib/sanitizers")))
                                                  """,
                                                  """
                                                   (with-filter (system-attribute apple-internal)
                                                     (allow file-read* (literal "/usr/local/share/posix_spawn_filtering_rules")))
                                                   (with-filter (system-attribute apple-internal)
                                                     (allow file-read* (subpath "/AppleInternal/Library/Preferences/Logging"))
                                                     (allow file-read* file-map-executable (subpath "/usr/local/lib/log")))
                                                  """,
                                
                                                "(allow file* file-read* file-read-metadata file-ioctl (literal \"/System/Library/Frameworks/Foundation.framework/Foundation\"))"
    ]
    
}

public func ==<K, L: Hashable, R: Hashable>(lhs: [K: L], rhs: [K: R] ) -> Bool {
   (lhs as NSDictionary).isEqual(to: rhs)
}

