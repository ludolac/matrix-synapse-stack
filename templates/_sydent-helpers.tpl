{{- /*
Default Waadoo-branded Sydent templates. Override per env via:
  .Values.sydent.templates.{invite,verification,verifyResponse}

The {{ .ServerName }} placeholder is injected so the rendered templates
inherit the sydent.serverName value. The signurl construction MUST point at
this server (Sydent rejects sign-ed25519 from foreign issuers).
*/}}

{{- define "matrix-synapse.sydent.defaultInviteTemplate" -}}
{{- $sn := .Values.sydent.serverName -}}
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

{{`{{ sender_display_name|safe }}`}} {{`{{ bracketed_verified_sender|safe }}`}}vous a invite a rejoindre {{`{% if room_type == "m.space" %}`}}l'espace{{`{% else %}`}}le salon{{`{% endif %}`}}
{{`{{ bracketed_room_name|safe }}`}}sur Waadoo Matrix.

Cliquez sur le lien ci-dessous pour rejoindre la conversation :

{{`{{ web_client_location }}`}}/#/room/{{`{{ room_id|urlencode }}`}}?email={{`{{ to|urlencode }}`}}&signurl=https%3A%2F%2F{{ $sn }}%2F_matrix%2Fidentity%2Fapi%2Fv1%2Fsign-ed25519%3Ftoken%3D{{`{{ token|urlencode }}`}}%26private_key%3D{{`{{ ephemeral_private_key|urlencode }}`}}&room_name={{`{{ room_name|urlencode }}`}}&room_avatar_url={{`{{ room_avatar_url|urlencode }}`}}&inviter_name={{`{{ sender_display_name|urlencode }}`}}&guest_access_token={{`{{ guest_access_token|urlencode }}`}}&guest_user_id={{`{{ guest_user_id|urlencode }}`}}&room_type={{`{{ room_type|urlencode }}`}}

Si vous n'avez pas encore de compte, le lien vous proposera d'en creer un.

A bientot,
Waadoo

--{{`{{ multipart_boundary|safe }}`}}
Content-Type: text/html; charset=UTF-8
Content-Disposition: inline

<!doctype html>
<html lang="fr">
  <head>
    <meta charset="utf-8" />
    <style>
      body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif; color: #333; line-height: 1.5; }
      .container { max-width: 560px; margin: 24px auto; padding: 24px; }
      h1 { color: #0dbd8b; font-size: 22px; }
      .button { display: inline-block; background: #0dbd8b; color: #fff !important; padding: 12px 24px; border-radius: 6px; text-decoration: none; font-weight: 600; }
      .footer { margin-top: 24px; color: #888; font-size: 12px; }
    </style>
  </head>
  <body>
    <div class="container">
      <h1>Invitation a rejoindre Waadoo Matrix</h1>
      <p>
        {{`{{ sender_display_name|safe }}`}} {{`{{ bracketed_verified_sender|safe }}`}}vous a invite a rejoindre
        {{`{% if room_type == "m.space" %}`}}l'espace{{`{% else %}`}}le salon{{`{% endif %}`}}
        <b>{{`{{ bracketed_room_name|safe }}`}}</b>.
      </p>
      <p>
        <a class="button" href="{{`{{ web_client_location }}`}}/#/room/{{`{{ room_id|urlencode }}`}}?email={{`{{ to|urlencode }}`}}&signurl=https%3A%2F%2F{{ $sn }}%2F_matrix%2Fidentity%2Fapi%2Fv1%2Fsign-ed25519%3Ftoken%3D{{`{{ token|urlencode }}`}}%26private_key%3D{{`{{ ephemeral_private_key|urlencode }}`}}&room_name={{`{{ room_name|urlencode }}`}}&room_avatar_url={{`{{ room_avatar_url|urlencode }}`}}&inviter_name={{`{{ sender_display_name|urlencode }}`}}&guest_access_token={{`{{ guest_access_token|urlencode }}`}}&guest_user_id={{`{{ guest_user_id|urlencode }}`}}&room_type={{`{{ room_type|urlencode }}`}}">
          Rejoindre la conversation
        </a>
      </p>
      <p class="footer">
        Si vous n'avez pas encore de compte Waadoo Matrix, le lien vous proposera d'en creer un.
      </p>
    </div>
  </body>
</html>

--{{`{{ multipart_boundary|safe }}`}}--
{{- end }}

{{- define "matrix-synapse.sydent.defaultVerificationTemplate" -}}
{{- $sn := .Values.sydent.serverName -}}
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

Si vous n'avez pas demande cette validation, ignorez cet email.

A bientot,
Waadoo

--{{`{{ multipart_boundary|safe }}`}}
Content-Type: text/html; charset=UTF-8
Content-Disposition: inline

<!doctype html>
<html lang="fr">
  <head><meta charset="utf-8" /></head>
  <body style="font-family:-apple-system,BlinkMacSystemFont,sans-serif;color:#333;max-width:560px;margin:24px auto;padding:24px;">
    <h1 style="color:#0dbd8b;font-size:22px;">Confirmer votre email</h1>
    <p>
      Pour confirmer cette adresse email sur Waadoo Matrix, cliquez sur le lien ci-dessous :
    </p>
    <p>
      <a style="display:inline-block;background:#0dbd8b;color:#fff;padding:12px 24px;border-radius:6px;text-decoration:none;font-weight:600;" href="{{`{{ link|safe }}`}}">
        Valider mon email
      </a>
    </p>
    <p style="margin-top:24px;color:#888;font-size:12px;">
      Si vous n'avez pas demande cette validation, ignorez cet email.
    </p>
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
