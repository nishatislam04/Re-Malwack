#!/system/bin/sh
# Re-Malwack Import Sources Script
# ALL respect for the developers of the mentioned modules/apps in this script.
# ZG089, Re-Malwack founder.

# ====== Variables ======
ABI="$(getprop ro.product.cpu.abi)"
PATH="$MODPATH/bin/$ABI:$PATH"
adaway_json="/sdcard/Download/adaway-backup.json"
import_done=0

# ====== Functions ======

# 1 - Dedup helper function
dedup_file() {
    file="$@"
    for i in $file; do
        [ -f "$i" ] || continue;
        awk '!seen[$0]++' "$i" > "$i.tmp" && mv "$i.tmp" "$i"
    done
}

# 2 - bindhosts import
bindhosts_import() {
    ui_print "[i] How do you want to import your setup?"
    ui_print "[i] Importing whitelist, blacklist, and sources only are supported."
    ui_print "1 - Import bindhosts setup"
    ui_print "2 - Skip importing. (Do not Import)"
    detect_key_press 2 2
    choice=$?

    case "$choice" in
        1)
            ui_print "[*] Replacing Re-Malwack setup with bindhosts setup..."
            bindhosts_import_helper sources
            bindhosts_import_helper whitelist
            bindhosts_import_helper blacklist
            bindhosts_import_helper custom
            ;;
        2|255) ui_print "[i] Skipped bindhosts import."; return ;;
        *) ui_print "[!] Invalid selection. Skipped bindhosts import."; return ;;
    esac

    ui_print "[✓] Bindhosts setup imported successfully."
}

# 2.1 - bindhosts import helper
bindhosts_import_helper() {
    list_type="$1"
    bindhosts="/data/adb/bindhosts"

    src="$bindhosts/$list_type.txt"
    dest="$persist_dir/$list_type.txt"
    [ "$list_type" = "custom" ] && dest="$persist_dir/custom_rules.txt"
    [ "$list_type" = "sources" ] && dest="$persist_dir/custom_source.txt"

    cp -f "$src" "$dest"
}

# 3 - cubic-adblock import
import_cubic_sources() {
    src_file="$persist_dir/custom_source.txt"
    ui_print "[i] How would you like to import cubic-adblock hosts sources?"
    ui_print "1 - Import cubic-adblock setup"
    ui_print "2 - Skip importing. (Do not Import)"

    detect_key_press 2 2
    choice=$?

    case "$choice" in
        1) ui_print "[*] Importing cubic-adblock setup..." ;;
        2|255) ui_print "[i] Skipped Cubic-Adblock import."; return ;;
        *) ui_print "[!] Invalid selection. Skipped Cubic-Adblock import."; return ;;
    esac

    # cubic-adblock sources
    cat <<EOF > "$src_file"
https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
https://gitlab.com/quidsup/notrack-blocklists/-/raw/master/malware.hosts?ref_type=heads
https://gitlab.com/quidsup/notrack-blocklists/-/raw/master/trackers.hosts?ref_type=heads
https://raw.githubusercontent.com/jerryn70/GoodbyeAds/master/Hosts/GoodbyeAds.txt
https://pgl.yoyo.org/adservers/serverlist.php?showintro=0;hostformat=hosts
https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/ultimate.txt
EOF
    ui_print "[✓] Cubic-Adblock sources imported successfully."
}

# 4 - AdAway import
import_adaway_data() {
    src_file="$persist_dir/custom_source.txt"
    whitelist_file="$persist_dir/whitelist.txt"
    blacklist_file="$persist_dir/blacklist.txt"

    ui_print "[i] AdAway Backup file has been detected."
    ui_print "[i] Do you want to import your setup from it?"
    ui_print "[i] Importing whitelist, blacklist, and sources only are supported."
    ui_print "1 - Import AdAway setup"
    ui_print "2 - Do Not Import."

    detect_key_press 2 2
    choice=$?

    case "$choice" in
        1) ui_print "[*] Applying AdAway setup..." ;;
        2|255) ui_print "[i] Skipped AdAway import."; return ;;
        *) ui_print "[!] Invalid selection. Skipped AdAway import."; return ;;
    esac

    jq -r '.sources[] | select(.enabled == true) | .url' "$adaway_json" > "$src_file"
    jq -r '.allowed[] | select(.enabled == true) | .host' "$adaway_json" > "$whitelist_file"
    jq -r '.blocked[] | select(.enabled == true) | .host' "$adaway_json" > "$blacklist_file"

    ui_print "[✓] AdAway import completed."
}

# ====== Main Script ======

# Exec perms for jq
chmod +x $MODPATH/bin/$ABI/jq
# AdAway import if backup exists
if [ -f "$adaway_json" ]; then
    import_adaway_data
    import_done=1
fi

# Detect other modules and run imports (only if not already imported)
for module in /data/adb/modules/*; do
    module_id="$(grep_prop id "${module}/module.prop")"
    module_name="$(grep_prop name "${module}/module.prop")"
    # skip if we got into our own module or any other module that 
    # is disabled already.
    if [ "${module_id}" == "Re-Malwack" ] || [ -f "/data/adb/modules/$module_id/disable" ] || [ ! -f "/data/adb/modules/$module_id/system/etc/hosts" ]; then
        continue;
    fi
    # force disable systemless hosts module
    [ "$module_id" = "hosts" ] && touch /data/adb/modules/hosts/disable
    if [ "$import_done" -eq 0 ]; then
        ui_print "[i] $module_name detected. Import setup?"
        ui_print "1 - YES | 2 - NO"
        detect_key_press 2 1
        choice=$?
        case "$choice" in
            1)
                case "$module_id" in
                    bindhosts)
                        bindhosts_import
                    ;;
                    cubic-adblock)
                        import_cubic_sources
                    ;;

                    *)
                        ui_print "[!] Importing from $module_id unsupported."
                    ;;
                esac
                # i feel like this variable does nothing - @bocchi-the-dev
                import_done=1
            ;;
            2)
                ui_print "[i] Skipped import from $module_id."
            ;;
            255)
                ui_print "[!] Timeout, skipping import from $module_id."
            ;;
            *)
                ui_print "[!] Invalid selection. Skipping import from $module_id."
            ;;
        esac
    fi
    # Always disable module, even if already imported
    ui_print "[*] Disabling: $module_name"
    touch "/data/adb/modules/$module_id/disable"
done

# Dedup everything at the end just in case
dedup_file "$persist_dir/custom_source.txt" "$persist_dir/whitelist.txt" "$persist_dir/blacklist.txt"
