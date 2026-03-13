const express = require('express');
const cors = require('cors');
const { MongoClient } = require('mongodb');

const app = express();
const PORT = process.env.PORT || 3000;
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://mongodb:27017/app';

app.use(cors());
app.use(express.json());

let db;
let messagesCollection;

async function connectDB() {
    const maxAttempts = 30;
    const delayMs = 2000;
    for (let attempt = 1; attempt <= maxAttempts; attempt++) {
        try {
            const client = await MongoClient.connect(MONGODB_URI);
            db = client.db();
            messagesCollection = db.collection('messages');
            await messagesCollection.createIndex({ createdAt: -1 });
            console.log('Connected to MongoDB');
            return;
        } catch (err) {
            console.warn(`MongoDB connection attempt ${attempt}/${maxAttempts} failed:`, err.message);
            if (attempt === maxAttempts) throw err;
            await new Promise((r) => setTimeout(r, delayMs));
        }
    }
}

app.get('/api/message', async (req, res) => {
    try {
        const messages = await messagesCollection
            .find()
            .sort({ createdAt: -1 })
            .limit(10)
            .toArray();
        const last = messages[0];
        res.json({
            message: last ? last.text : 'Aucun message en base',
            messages
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.post('/api/message', async (req, res) => {
    try {
        const { text } = req.body;
        if (!text) {
            return res.status(400).json({ error: 'text requis' });
        }
        const doc = { text, createdAt: new Date() };
        await messagesCollection.insertOne(doc);
        res.status(201).json(doc);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

connectDB()
    .then(() => {
        app.listen(PORT, () => {
            console.log('Backend running on port 3000');
        });
    })
    .catch((err) => {
        console.error('MongoDB connection failed:', err);
        process.exit(1);
    });
