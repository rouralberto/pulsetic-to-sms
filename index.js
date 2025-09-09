const twilio = require('twilio');

// Environment variables for Twilio configuration
const accountSid = process.env.TWILIO_ACCOUNT_SID;
const authToken = process.env.TWILIO_AUTH_TOKEN;
const fromNumber = process.env.TWILIO_FROM_NUMBER;
const toNumber = process.env.TO_NUMBER;

// Initialize Twilio client
const client = twilio(accountSid, authToken);

exports.handler = async (event) => {
    console.log('Received event:', JSON.stringify(event, null, 2));

    try {
        // Parse the request body
        let body;
        if (event.body) {
            body = typeof event.body === 'string' ? JSON.parse(event.body) : event.body;
        } else {
            throw new Error('No body found in request');
        }

        console.log('Parsed body:', JSON.stringify(body, null, 2));

        // Extract Pulsetic notification data
        const alertType = body.alert_type || 'unknown';
        const monitor = body.monitor;

        if (!monitor) {
            throw new Error('Invalid Pulsetic notification format - no monitor data found');
        }

        // Create title and description based on alert type and monitor data
        let title = 'Pulsetic Alert';
        let description = '';

        switch (alertType) {
            case 'monitor_offline':
                title = `🚨 Monitor Offline: ${monitor.name}`;
                description = `URL: ${monitor.url}\nResponse Code: ${monitor.response_code}\nReason: ${monitor.fail_reason || 'Unknown'}`;
                break;
            case 'monitor_online':
                title = `✅ Monitor Online: ${monitor.name}`;
                description = `URL: ${monitor.url}\nMonitor is back online`;
                break;
            default:
                title = `📊 Pulsetic Alert: ${monitor.name}`;
                description = `URL: ${monitor.url}\nAlert Type: ${alertType}`;
        }

        // Create SMS message from the Pulsetic alert
        const smsMessage = `${title}\n\n${description}`;

        console.log('Sending SMS:', smsMessage);

        // Send SMS via Twilio
        const message = await client.messages.create({
            body: smsMessage,
            to: toNumber,
            from: fromNumber,
        });

        console.log('SMS sent successfully. Message SID:', message.sid);

        return {
            statusCode: 200,
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                success: true,
                message: 'SMS sent successfully',
                messageSid: message.sid
            }),
        };

    } catch (error) {
        console.error('Error processing Pulsetic alert:', error);

        return {
            statusCode: 500,
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                success: false,
                error: error.message
            }),
        };
    }
};
