@extends('Template::layouts.master')

@section('content')
    <section class="py-60">
        <div class="container">
            <div class="row">
                <div class="col-lg-10 mx-auto">
                    <h1 class="mb-4">Privacy Policy</h1>
                    <p class="text-muted mb-4">Last updated: {{ now()->format('F j, Y') }}</p>

                    <p>JollyBoxfr ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our website, mobile application, and services (together, the "Services"). Please read this policy carefully.</p>

                    <h2 class="h5 mt-4 mb-2">1. Information We Collect</h2>
                    <p>We may collect information that you provide directly to us, including:</p>
                    <ul>
                        <li><strong>Account information:</strong> name, email address, password (stored securely), and optionally phone number when you register or update your profile.</li>
                        <li><strong>Order and shipping information:</strong> recipient name, address, city, state/region, postal code, country, and phone number for delivery of gifts.</li>
                        <li><strong>Payment information:</strong> payment is processed by secure third-party providers. We do not store full card numbers on our servers.</li>
                        <li><strong>Photos and custom content:</strong> when you upload photos or custom text for personalized gift products, we store and process these only to fulfill your order.</li>
                        <li><strong>Communications:</strong> messages you send to us (e.g. support, contact forms) and order-related communications.</li>
                    </ul>

                    <h2 class="h5 mt-4 mb-2">2. How We Use Your Information</h2>
                    <p>We use the information we collect to:</p>
                    <ul>
                        <li>Provide, maintain, and improve our Services (including order processing, delivery, and customer support).</li>
                        <li>Process payments and prevent fraud.</li>
                        <li>Send order confirmations, shipping updates, and tracking information.</li>
                        <li>Respond to your requests and communicate with you.</li>
                        <li>Comply with legal obligations and enforce our terms.</li>
                        <li>Improve our app and website experience (e.g. analytics in a way that does not personally identify you where possible).</li>
                    </ul>

                    <h2 class="h5 mt-4 mb-2">3. Photo and Camera Access (Mobile App)</h2>
                    <p>Our mobile app may request access to your device’s photo library and camera so you can upload images for customized gift products. We use these images only to fulfill your order and do not use them for marketing or other purposes without your consent. You can deny or revoke access in your device settings at any time.</p>

                    <h2 class="h5 mt-4 mb-2">4. Sharing of Information</h2>
                    <p>We may share your information with:</p>
                    <ul>
                        <li><strong>Service providers:</strong> payment processors, shipping carriers, hosting and infrastructure providers, and support tools, under strict confidentiality and data-processing agreements.</li>
                        <li><strong>Legal and safety:</strong> when required by law, to protect our rights, or to prevent fraud or harm.</li>
                    </ul>
                    <p>We do not sell your personal information to third parties for their marketing.</p>

                    <h2 class="h5 mt-4 mb-2">5. Data Security</h2>
                    <p>We use industry-standard measures (including encryption and secure connections) to protect your data. No method of transmission or storage is 100% secure; we encourage you to use a strong password and keep your account details private.</p>

                    <h2 class="h5 mt-4 mb-2">6. Data Retention</h2>
                    <p>We retain your information for as long as your account is active or as needed to provide the Services, comply with law, resolve disputes, and enforce our agreements. Order and transaction data may be retained for legal and accounting purposes as required.</p>

                    <h2 class="h5 mt-4 mb-2">7. Your Rights</h2>
                    <p>Depending on your location, you may have the right to access, correct, delete, or restrict use of your personal data, or to data portability. You can update account details in the app or by contacting us. To exercise other rights or ask questions, contact us using the details below.</p>

                    <h2 class="h5 mt-4 mb-2">8. Children</h2>
                    <p>Our Services are not directed to individuals under the age of 16. We do not knowingly collect personal information from children under 16. If you become aware that a child has provided us with personal information, please contact us so we can delete it.</p>

                    <h2 class="h5 mt-4 mb-2">9. International Transfers</h2>
                    <p>Your information may be processed in countries other than your own. We ensure appropriate safeguards are in place so your data remains protected in line with this policy and applicable law.</p>

                    <h2 class="h5 mt-4 mb-2">10. Changes to This Policy</h2>
                    <p>We may update this Privacy Policy from time to time. We will post the revised policy on this page and update the "Last updated" date. Continued use of the Services after changes constitutes acceptance of the updated policy. For material changes, we may provide additional notice (e.g. in the app or by email).</p>

                    <h2 class="h5 mt-4 mb-2">11. Contact Us</h2>
                    <p>If you have questions about this Privacy Policy or our data practices, please contact us:</p>
                    <p>
                        <strong>JollyBoxfr</strong><br>
                        Via our website contact form or the contact details published on {{ gs('site_name') ?? config('app.name') }}.
                    </p>
                </div>
            </div>
        </div>
    </section>
@endsection
