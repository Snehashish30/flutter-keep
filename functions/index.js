const functions = require("firebase-functions");

const admin = require('firebase-admin');
admin.initializeApp(functions.config().firebase);

const SENDGRID_API_KEY = functions.config().sendgrid.key

const sgMail = require('@sendgrid/mail');
sgMail.setApiKey(SENDGRID_API_KEY);

exports.firestoreEmail = functions.firestore
    .document('users/{userId}/followers/{followerId}')
    .onCreate((snap, context) => {
        const userId = context.params.userId;
		console.log('Displaying UserId');
		console.log(userId);
        const db = admin.firestore()

        return  db.collection('users').doc(userId)
            .get()
            .then(doc => {
                const user = doc.data()

                const msg = {
                    to: user.email,
                    from: 'paulsubhashish13@gmail.com',
                    subject: 'Claim Intimation',
                    templateId: 'd-efc4577efc6b479791ab89c8663aa1b0',
                    substitutionWrappers: ['{{','}}'],
                    substitutions: {
                        name: user.displayName
                    }

                };

                return sgMail.send(msg)
                })
                .then(() => console.log('email sent'))
                .catch(err => console.log(err))
        });