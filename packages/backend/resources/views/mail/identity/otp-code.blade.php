<x-mail::message>
# Your sign-in code

Use this code to sign in to {{ config('app.name') }}:

<x-mail::panel>
<strong style="font-size: 28px; letter-spacing: 6px;">{{ $code }}</strong>
</x-mail::panel>

The code expires in {{ $expiresInMinutes }} minutes and can be used only once.
If you did not request it, you can ignore this email.

Thanks,<br>
{{ config('app.name') }}
</x-mail::message>
