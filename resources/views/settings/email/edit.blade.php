<x-layouts.admin>
    <x-slot name="title">{{ trans('settings.email.email_service') }}</x-slot>

    <x-slot name="content">
        <x-form.container>
            <x-form id="setting" method="PATCH" route="settings.email.update">
                <x-form.section>
                    <x-slot name="head">
                        <x-form.section.head title="{{ trans('general.general') }}" description="{{ trans('settings.email.form_description.general') }}" />
                    </x-slot>

                    <x-slot name="body">
                        <x-form.group.select name="protocol" label="{{ trans('settings.email.protocol') }}" :options="$email_protocols" :selected="setting('email.protocol')" not-required change="onChangeProtocol" />

                        <x-form.group.password name="sendgrid_api_key" label="{{ trans('settings.email.sendgrid_api_key') }}" value="{{ setting('email.sendgrid_api_key') }}" v-show="email.showSendgridKey" not-required />

                        <x-form.group.text name="sendmail_path" label="{{ trans('settings.email.sendmail_path') }}" value="{{ setting('email.sendmail_path') }}" v-show="email.showSendmailPath" not-required />

                        <x-form.group.text name="smtp_host" label="{{ trans('settings.email.smtp.host') }}" value="{{ setting('email.smtp_host') }}" v-show="email.showSmtp" not-required />

                        <x-form.group.text name="smtp_port" label="{{ trans('settings.email.smtp.port') }}" value="{{ setting('email.smtp_port') }}" v-show="email.showSmtp" not-required />

                        <x-form.group.text name="smtp_username" label="{{ trans('settings.email.smtp.username') }}" value="{{ setting('email.smtp_username') }}" v-show="email.showSmtp" not-required />

                        <x-form.group.password name="smtp_password" label="{{ trans('settings.email.smtp.password') }}" value="{{ setting('email.smtp_password') }}" v-show="email.showSmtp" not-required />

                        <x-form.group.select name="smtp_encryption" label="{{ trans('settings.email.smtp.encryption') }}" :options="['' => trans('settings.email.smtp.none'), 'ssl' => 'SSL', 'tls' => 'TLS']" :selected="setting('email.smtp_encryption', null)" v-show="email.showSmtp" not-required />
                    </x-slot>
                </x-form.section>

                @can('update-settings-email')
                <x-form.section>
                    <x-slot name="foot">
                        <x-form.buttons :cancel="url()->previous()" />
                    </x-slot>
                </x-form.section>
                @endcan

                <x-form.input.hidden name="_prefix" value="email" />
            </x-form>
        </x-form.container>
    </x-slot>

    <x-script folder="settings" file="settings" />
</x-layouts.admin>
