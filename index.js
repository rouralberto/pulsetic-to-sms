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
        if (!body.embeds || !Array.isArray(body.embeds) || body.embeds.length === 0) {
            throw new Error('Invalid Pulsetic notification format - no embeds found');
        }

        const embed = body.embeds[0];
        const title = embed.title || 'Pulsetic Alert';
        const description = embed.description || 'No description provided';

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
