<x-mail::message>
# Seu código de acesso

Use este código para entrar no {{ config('app.name') }}:

<x-mail::panel>
<strong style="font-size: 28px; letter-spacing: 6px;">{{ $code }}</strong>
</x-mail::panel>

O código expira em {{ $expiresInMinutes }} minutos e só pode ser usado uma vez.
Se você não pediu este código, pode ignorar este e-mail.

Obrigado,<br>
{{ config('app.name') }}
</x-mail::message>
