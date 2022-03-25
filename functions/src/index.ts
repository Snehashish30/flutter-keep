import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
admin.initializeApp();
const db = admin.firestore();

export const taskRunner = functions.runWith( { memory: '2GB' }).pubsub

    .schedule('* * * * *').onRun(async context => {

        // Consistent timestamp
        const now = admin.firestore.Timestamp.now();

        // Query all documents ready to perform
        const query = db.collection('tasks').where('performAt', '<=', now).where('status', '==', 'scheduled');

        const tasks = await query.get();


        // Jobs to execute concurrently.
        const jobs: Promise<any>[] = [];

        // Loop over documents and push job.
        tasks.forEach(snapshot => {
            const { worker, options} = snapshot.data();
            const newOptions = new Map(Object.entries(options));
			const phoneNum = newOptions.get('phoneNumber');
			const location = newOptions.get('location');
			//console.log('Showing New Options');
			//console.log(newOptions);
			//console.log('Showing Derived value');
			console.log(phoneNum);
			console.log(location);
            const job = workers[worker](newOptions)

                // Update doc with status on success or error
                .then(() => snapshot.ref.update({ status: 'complete' }))
                .catch((err) => snapshot.ref.update({ status: 'error' }));

            jobs.push(job);
        });

        // Execute all jobs concurrently
        return await Promise.all(jobs);

});

// Optional interface, all worker functions should return Promise.
interface Workers {
    [key: string]: (newOptions: any) => Promise<any>
}

// Business logic for named tasks. Function name should match worker field on task document.
const workers: Workers = {
    helloWorld: () => db.collection('logs').add({ hello: 'world' }),
	helloWorldSpecific: (newOptions) => db.collection('logs').add({ hello: 'world', to: 'me', by : newOptions.get('phoneNumber'), from: newOptions.get('location') })
}