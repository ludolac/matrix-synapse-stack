{{- /*
Default Waadoo-branded Sydent templates. Override per env via:
  .Values.sydent.templates.{invite,verification,verifyResponse}

The {{ .ServerName }} placeholder is injected so the rendered templates
inherit the sydent.serverName value. The signurl construction MUST point at
this server (Sydent rejects sign-ed25519 from foreign issuers).
*/}}

{{- define "matrix-synapse.sydent.defaultInviteTemplate" -}}
{{- $sn := .Values.sydent.serverName -}}
{{- $logoUrl := .Values.sydent.email.logoUrl | default "" -}}
{{- $joinUrl := printf "{{ web_client_location }}/#/room/{{ room_id|urlencode }}?email={{ to|urlencode }}&signurl=https%%3A%%2F%%2F%s%%2F_matrix%%2Fidentity%%2Fapi%%2Fv1%%2Fsign-ed25519%%3Ftoken%%3D{{ token|urlencode }}%%26private_key%%3D{{ ephemeral_private_key|urlencode }}&room_name={{ room_name|urlencode }}&room_avatar_url={{ room_avatar_url|urlencode }}&inviter_name={{ sender_display_name|urlencode }}&guest_access_token={{ guest_access_token|urlencode }}&guest_user_id={{ guest_user_id|urlencode }}&room_type={{ room_type|urlencode }}" $sn -}}
Date: {{`{{ date|safe }}`}}
From: {{`{{ from|safe }}`}}
To: {{`{{ to|safe }}`}}
Message-ID: {{`{{ messageid|safe }}`}}
Subject: {{`{{ subject_header_value|safe }}`}}
MIME-Version: 1.0
Content-Type: multipart/alternative;
	boundary="{{`{{ multipart_boundary|safe }}`}}"

--{{`{{ multipart_boundary|safe }}`}}
Content-Type: text/plain; charset=UTF-8
Content-Disposition: inline

Bonjour,

{{`{{ sender_display_name|safe }}`}} {{`{{ bracketed_verified_sender|safe }}`}}vous invite à rejoindre {{`{% if room_type == "m.space" %}`}}l'espace{{`{% else %}`}}le salon{{`{% endif %}`}} {{`{{ bracketed_room_name|safe }}`}}sur Waadoo Matrix.

Pour rejoindre la conversation, cliquez sur le lien ci-dessous :

{{ $joinUrl }}

Vous n'avez pas encore de compte ? L'inscription se fait en 2 étapes :

  1. Le lien ci-dessus vous amène sur la page d'inscription. Vous devrez
     y saisir un CODE D'INVITATION (token d'enregistrement) fourni
     séparément par Waadoo. Si vous n'en avez pas, contactez la personne
     qui vous a invité ou écrivez à contact@waadoo.ovh.

  2. Une fois le code saisi, vous recevrez un SECOND EMAIL contenant un
     code de vérification à 6 chiffres pour confirmer cette adresse.

---
Waadoo Matrix
Cet email vous est envoyé à la demande de {{`{{ sender_display_name|safe }}`}}.
Conditions d'utilisation : https://waadoo.ovh/terms
Politique de confidentialité : https://waadoo.ovh/privacy

--{{`{{ multipart_boundary|safe }}`}}
Content-Type: text/html; charset=UTF-8
Content-Disposition: inline

<!doctype html>
<html lang="fr">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <meta name="x-apple-disable-message-reformatting" />
    <title>Invitation Waadoo Matrix</title>
    <style type="text/css">
      body, html { margin: 0; padding: 0; }
      table { border-collapse: collapse; }
      img { display: block; border: 0; outline: none; text-decoration: none; }
      a { color: #0dbd8b; }
      body {
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
        color: #1a1d23;
        background-color: #f5f6f7;
        -webkit-font-smoothing: antialiased;
        line-height: 1.5;
      }
      .container { max-width: 600px; margin: 24px auto; background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,0.06); }
      .header { background: linear-gradient(135deg, #0dbd8b 0%, #0a9d75 100%); padding: 36px 24px; text-align: center; color: #ffffff; }
      .header h1 { margin: 0; font-size: 22px; font-weight: 700; letter-spacing: -0.01em; }
      .header .badge { display: inline-block; background-color: rgba(255,255,255,0.18); padding: 4px 12px; border-radius: 20px; font-size: 12px; font-weight: 600; margin-bottom: 12px; letter-spacing: 0.05em; text-transform: uppercase; }
      .content { padding: 32px 28px; }
      .room-card { background-color: #f5f6f7; border-left: 4px solid #0dbd8b; padding: 16px 20px; border-radius: 8px; margin: 24px 0; }
      .room-card .label { font-size: 11px; color: #6b7280; text-transform: uppercase; letter-spacing: 0.08em; margin-bottom: 6px; font-weight: 600; }
      .room-card .name { font-size: 18px; font-weight: 600; color: #1a1d23; word-break: break-word; }
      .button-wrap { text-align: center; margin: 32px 0 20px; }
      .button { display: inline-block; background-color: #0dbd8b; color: #ffffff !important; padding: 14px 36px; text-decoration: none; font-weight: 600; border-radius: 8px; font-size: 16px; box-shadow: 0 2px 4px rgba(13,189,139,0.25); }
      .fallback-label { font-size: 13px; color: #6b7280; text-align: center; margin-bottom: 8px; }
      .fallback { font-size: 12px; color: #4b5563; word-break: break-all; padding: 12px 14px; background-color: #f5f6f7; border-radius: 6px; font-family: ui-monospace, "SF Mono", monospace; }
      .info { background-color: #eef9f5; border-radius: 8px; padding: 16px 18px; margin-top: 28px; font-size: 14px; color: #0a5d4a; }
      .info b { color: #0dbd8b; }
      .info ol { padding-left: 22px; margin: 10px 0 0; }
      .info ol li { margin-bottom: 8px; }
      .info ol li:last-child { margin-bottom: 0; }
      .info .step-label { display: inline-block; background-color: #0dbd8b; color: #ffffff; font-size: 11px; font-weight: 700; padding: 2px 8px; border-radius: 10px; margin-right: 6px; letter-spacing: 0.05em; text-transform: uppercase; }
      .footer { padding: 20px 24px; text-align: center; font-size: 12px; color: #9ca3af; border-top: 1px solid #f3f4f6; line-height: 1.6; }
      .footer a { color: #6b7280; text-decoration: none; }
      .footer .sep { color: #d1d5db; padding: 0 6px; }
      @media only screen and (max-width: 600px) {
        .container { margin: 0; border-radius: 0; }
        .header { padding: 28px 16px; }
        .content { padding: 24px 16px; }
        .footer { padding: 20px 16px; }
        .button { display: block !important; padding: 14px 16px; }
      }
    </style>
  </head>
  <body>
    <table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%" style="background-color:#f5f6f7;">
      <tr>
        <td align="center">
          <div class="container">
            <div class="header">
              {{- if $logoUrl }}
              <img src="{{ $logoUrl }}" alt="Waadoo" height="48" style="display:inline-block;margin-bottom:16px;max-height:48px;height:48px;width:auto;border:0;" />
              {{- end }}
              <div class="badge">{{`{% if room_type == "m.space" %}`}}Espace{{`{% else %}`}}Salon{{`{% endif %}`}}</div>
              <h1>Vous êtes invité sur Waadoo Matrix</h1>
            </div>
            <div class="content">
              <p style="margin-top:0;">
                <b>{{`{{ sender_display_name|safe }}`}}</b> {{`{{ bracketed_verified_sender|safe }}`}}
                vous invite à rejoindre
                {{`{% if room_type == "m.space" %}`}}l'espace{{`{% else %}`}}le salon{{`{% endif %}`}}
                ci-dessous.
              </p>

              {{`{% if room_name %}`}}
              <div class="room-card">
                <div class="label">{{`{% if room_type == "m.space" %}`}}Espace{{`{% else %}`}}Salon{{`{% endif %}`}}</div>
                <div class="name">{{`{{ room_name|safe }}`}}</div>
              </div>
              {{`{% endif %}`}}

              <div class="button-wrap">
                <a class="button" href="{{ $joinUrl }}">Rejoindre la conversation</a>
              </div>

              <p class="fallback-label">Le bouton ne fonctionne pas ? Copiez ce lien dans votre navigateur :</p>
              <div class="fallback">{{ $joinUrl }}</div>

              <div class="info">
                <p style="margin:0 0 6px;"><b>Pas encore de compte ? Inscription en 2 étapes :</b></p>
                <ol>
                  <li>
                    <span class="step-label">Étape 1</span>
                    Le lien ci-dessus vous amène sur la page d'inscription. Saisissez
                    le <b>code d'invitation</b> (token d'enregistrement) fourni
                    séparément par Waadoo. Vous ne l'avez pas ?
                    Demandez-le à la personne qui vous a invité, ou écrivez à
                    <a href="mailto:contact@waadoo.ovh">contact@waadoo.ovh</a>.
                  </li>
                  <li>
                    <span class="step-label">Étape 2</span>
                    Vous recevrez ensuite un <b>second email</b> contenant un
                    code à 6 chiffres pour vérifier cette adresse. Saisissez-le
                    sur la page d'inscription pour finaliser la création du
                    compte.
                  </li>
                </ol>
              </div>
            </div>
            <div class="footer">
              Envoyé à la demande de <b>{{`{{ sender_display_name|safe }}`}}</b>.<br>
              <a href="https://waadoo.ovh/terms">Conditions d'utilisation</a>
              <span class="sep">&middot;</span>
              <a href="https://waadoo.ovh/privacy">Confidentialite</a>
            </div>
          </div>
        </td>
      </tr>
    </table>
  </body>
</html>

--{{`{{ multipart_boundary|safe }}`}}--
{{- end }}

{{- define "matrix-synapse.sydent.defaultVerificationTemplate" -}}
{{- $logoUrl := .Values.sydent.email.logoUrl | default "" -}}
Date: {{`{{ date|safe }}`}}
From: {{`{{ from|safe }}`}}
To: {{`{{ to|safe }}`}}
Message-ID: {{`{{ messageid|safe }}`}}
Subject: {{`{{ subject_header_value|safe }}`}}
MIME-Version: 1.0
Content-Type: multipart/alternative;
	boundary="{{`{{ multipart_boundary|safe }}`}}"

--{{`{{ multipart_boundary|safe }}`}}
Content-Type: text/plain; charset=UTF-8
Content-Disposition: inline

Bonjour,

Pour confirmer cette adresse email sur Waadoo Matrix, cliquez sur le lien ci-dessous :

{{`{{ link|safe }}`}}

Si vous n'avez pas demandé cette validation, ignorez cet email.

À bientôt,
Waadoo

--{{`{{ multipart_boundary|safe }}`}}
Content-Type: text/html; charset=UTF-8
Content-Disposition: inline

<!doctype html>
<html lang="fr">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  </head>
  <body style="margin:0;padding:0;background-color:#f5f6f7;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Helvetica,Arial,sans-serif;color:#1a1d23;">
    <table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%" style="background-color:#f5f6f7;">
      <tr>
        <td align="center">
          <div style="max-width:560px;margin:24px auto;background-color:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,0.06);">
            <div style="background:linear-gradient(135deg,#0dbd8b 0%,#0a9d75 100%);padding:32px 24px;text-align:center;color:#ffffff;">
              {{- if $logoUrl }}
              <img src="{{ $logoUrl }}" alt="Waadoo" height="48" style="display:inline-block;margin-bottom:16px;max-height:48px;height:48px;width:auto;border:0;" />
              {{- end }}
              <h1 style="margin:0;font-size:22px;font-weight:700;">Confirmer votre adresse email</h1>
            </div>
            <div style="padding:32px 28px;line-height:1.5;">
              <p style="margin-top:0;">Bonjour,</p>
              <p>
                Pour finaliser la validation de cette adresse email sur Waadoo Matrix,
                cliquez sur le bouton ci-dessous :
              </p>
              <div style="text-align:center;margin:32px 0;">
                <a href="{{`{{ link|safe }}`}}" style="display:inline-block;background-color:#0dbd8b;color:#ffffff !important;padding:14px 36px;text-decoration:none;font-weight:600;border-radius:8px;font-size:16px;box-shadow:0 2px 4px rgba(13,189,139,0.25);">
                  Valider mon email
                </a>
              </div>
              <p style="font-size:13px;color:#6b7280;text-align:center;">
                Le bouton ne fonctionne pas ? Copiez ce lien dans votre navigateur :
              </p>
              <div style="font-size:12px;color:#4b5563;word-break:break-all;padding:12px 14px;background-color:#f5f6f7;border-radius:6px;font-family:ui-monospace,'SF Mono',monospace;">
                {{`{{ link|safe }}`}}
              </div>
              <p style="margin-top:28px;color:#6b7280;font-size:13px;">
                Si vous n'êtes pas à l'origine de cette demande, ignorez ce message —
                aucune adresse ne sera ajoutée à votre compte.
              </p>
            </div>
            <div style="padding:20px 24px;text-align:center;font-size:12px;color:#9ca3af;border-top:1px solid #f3f4f6;">
              <a href="https://waadoo.ovh/terms" style="color:#6b7280;text-decoration:none;">Conditions d'utilisation</a>
              <span style="color:#d1d5db;padding:0 6px;">&middot;</span>
              <a href="https://waadoo.ovh/privacy" style="color:#6b7280;text-decoration:none;">Confidentialité</a>
            </div>
          </div>
        </td>
      </tr>
    </table>
  </body>
</html>

--{{`{{ multipart_boundary|safe }}`}}--
{{- end }}

{{- define "matrix-synapse.sydent.defaultVerifyResponseTemplate" -}}
<!DOCTYPE html>
<html lang="fr">
  <head>
    <meta charset="utf-8" />
    <title>Waadoo Matrix - Validation</title>
    <style>
      body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; color: #333; max-width: 560px; margin: 48px auto; padding: 24px; text-align: center; }
      h1 { color: #0dbd8b; }
    </style>
  </head>
  <body>
    <h1>Waadoo Matrix</h1>
    <p>%(message)s</p>
  </body>
</html>
{{- end }}
