#!/bin/bash

# Lade globale Konfigurationen
source /opt/splitdns/globals.conf

# Netzwerkschnittstelle und Gateway aus globals.sh
INTERFACE="${DEFAULT_LANIF}"
GATEWAY="${DEFAULT_WANGW}"

# Funktion: Setzt direkte statische Routen für Domains aus einem Array
set_routes_for_domains() {
  local DOMAIN_LIST_NAME=$1  # Name der Array-Variable, z. B. MAIL_SERVERS

  echo "⚙️  Verarbeite $DOMAIN_LIST_NAME..."

  # Referenz auf die Array-Variable (indirekte Referenz mit nameref)
  local -n DOMAINS_REF=$DOMAIN_LIST_NAME

  for DOMAIN in "${DOMAINS_REF[@]}"; do
    DOMAIN_CLEANED=$(echo "$DOMAIN" | sed 's/\.$//')  # Entferne evtl. finalen Punkt
    echo "🔍 Resolving $DOMAIN_CLEANED..."
    IPS=$(dig +short A "$DOMAIN_CLEANED" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$')
    
    if [[ -z "$IPS" ]]; then
      echo "⚠️  Keine IPs für $DOMAIN_CLEANED gefunden – übersprungen"
      continue
    fi

    for IP in $IPS; do
      echo "➕ Route für $IP via $GATEWAY ($INTERFACE)"
      ip route replace "$IP" via "$GATEWAY" dev "$INTERFACE"
    done
  done

  echo "✅ Fertig: $DOMAIN_LIST_NAME"
}

# Setze statische Routen für alle Domain-Listen
set_routes_for_domains MAIL_SERVERS
set_routes_for_domains CLEARDOMAINS
set_routes_for_domains MIRRORDOMAINS
