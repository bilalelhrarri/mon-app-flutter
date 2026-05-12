import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime

cred = credentials.Certificate("medapp-bilal-01-firebase-adminsdk-fbsvc-e5faa7df76.json")
firebase_admin.initialize_app(cred)

db = firestore.client()

trucks = [
    {"plaque": "MA-1234-A", "chauffeur": "Mohamed Alami", "telephone": "0661234501", "statut": "en_attente"},
    {"plaque": "MA-2345-B", "chauffeur": "Youssef Bennani", "telephone": "0661234502", "statut": "en_port"},
    {"plaque": "MA-3456-C", "chauffeur": "Karim Fassi", "telephone": "0661234503", "statut": "sorti"},
    {"plaque": "MA-4567-D", "chauffeur": "Omar Tazi", "telephone": "0661234504", "statut": "en_attente"},
    {"plaque": "MA-5678-E", "chauffeur": "Hassan Idrissi", "telephone": "0661234505", "statut": "en_port"},
    {"plaque": "MA-6789-F", "chauffeur": "Rachid Chaoui", "telephone": "0661234506", "statut": "sorti"},
    {"plaque": "MA-7890-G", "chauffeur": "Bilal Ziani", "telephone": "0661234507", "statut": "en_attente"},
    {"plaque": "MA-8901-H", "chauffeur": "Amine Berrada", "telephone": "0661234508", "statut": "en_port"},
    {"plaque": "MA-9012-I", "chauffeur": "Nabil Squalli", "telephone": "0661234509", "statut": "en_attente"},
    {"plaque": "MA-1023-J", "chauffeur": "Tariq Hamdani", "telephone": "0661234510", "statut": "sorti"},
    {"plaque": "MA-1124-K", "chauffeur": "Said Lamrani", "telephone": "0661234511", "statut": "en_port"},
    {"plaque": "MA-1225-L", "chauffeur": "Mehdi Ouazzani", "telephone": "0661234512", "statut": "en_attente"},
    {"plaque": "MA-1326-M", "chauffeur": "Hamza Filali", "telephone": "0661234513", "statut": "sorti"},
    {"plaque": "MA-1427-N", "chauffeur": "Zakaria Benali", "telephone": "0661234514", "statut": "en_port"},
    {"plaque": "MA-1528-O", "chauffeur": "Adil Chraibi", "telephone": "0661234515", "statut": "en_attente"},
    {"plaque": "MA-1629-P", "chauffeur": "Mustapha Rami", "telephone": "0661234516", "statut": "en_port"},
    {"plaque": "MA-1730-Q", "chauffeur": "Khalid Mansouri", "telephone": "0661234517", "statut": "sorti"},
    {"plaque": "MA-1831-R", "chauffeur": "Hicham Kettani", "telephone": "0661234518", "statut": "en_attente"},
    {"plaque": "MA-1932-S", "chauffeur": "Othmane Ghazi", "telephone": "0661234519", "statut": "en_port"},
    {"plaque": "MA-2033-T", "chauffeur": "Jawad Bensouda", "telephone": "0661234520", "statut": "sorti"},
    {"plaque": "MA-2134-U", "chauffeur": "Reda Alaoui", "telephone": "0661234521", "statut": "en_attente"},
    {"plaque": "MA-2235-V", "chauffeur": "Soufiane Tahiri", "telephone": "0661234522", "statut": "en_port"},
    {"plaque": "MA-2336-W", "chauffeur": "Ayoub Benkirane", "telephone": "0661234523", "statut": "en_attente"},
    {"plaque": "MA-2437-X", "chauffeur": "Ilyas Sabir", "telephone": "0661234524", "statut": "sorti"},
    {"plaque": "MA-2538-Y", "chauffeur": "Badr Tounsi", "telephone": "0661234525", "statut": "en_port"},
    {"plaque": "MA-2639-Z", "chauffeur": "Anass Rifai", "telephone": "0661234526", "statut": "en_attente"},
    {"plaque": "MA-2740-A", "chauffeur": "Imad Benchekroun", "telephone": "0661234527", "statut": "en_port"},
    {"plaque": "MA-2841-B", "chauffeur": "Saad Lahlou", "telephone": "0661234528", "statut": "sorti"},
    {"plaque": "MA-2942-C", "chauffeur": "Faris Bennis", "telephone": "0661234529", "statut": "en_attente"},
    {"plaque": "MA-3043-D", "chauffeur": "Anas Tahiri", "telephone": "0661234530", "statut": "en_port"},
    {"plaque": "MA-3144-E", "chauffeur": "Yassir Amrani", "telephone": "0661234531", "statut": "sorti"},
    {"plaque": "MA-3245-F", "chauffeur": "Hatim Skalli", "telephone": "0661234532", "statut": "en_attente"},
    {"plaque": "MA-3346-G", "chauffeur": "Walid Benomar", "telephone": "0661234533", "statut": "en_port"},
    {"plaque": "MA-3447-H", "chauffeur": "Nassim Cherif", "telephone": "0661234534", "statut": "sorti"},
    {"plaque": "MA-3548-I", "chauffeur": "Rayan Sefrioui", "telephone": "0661234535", "statut": "en_attente"},
    {"plaque": "MA-3649-J", "chauffeur": "Ismail Bargach", "telephone": "0661234536", "statut": "en_port"},
    {"plaque": "MA-3750-K", "chauffeur": "Younes Lazrak", "telephone": "0661234537", "statut": "sorti"},
    {"plaque": "MA-3851-L", "chauffeur": "Chadi Benabdellah", "telephone": "0661234538", "statut": "en_attente"},
    {"plaque": "MA-3952-M", "chauffeur": "Tarik Zemmouri", "telephone": "0661234539", "statut": "en_port"},
    {"plaque": "MA-4053-N", "chauffeur": "Marouane Fassi", "telephone": "0661234540", "statut": "sorti"},
    {"plaque": "MA-4154-O", "chauffeur": "Driss Benhima", "telephone": "0661234541", "statut": "en_attente"},
    {"plaque": "MA-4255-P", "chauffeur": "Ghali Bensouda", "telephone": "0661234542", "statut": "en_port"},
    {"plaque": "MA-4356-Q", "chauffeur": "Ziad Alaoui", "telephone": "0661234543", "statut": "sorti"},
    {"plaque": "MA-4457-R", "chauffeur": "Sami Chraibi", "telephone": "0661234544", "statut": "en_attente"},
    {"plaque": "MA-4558-S", "chauffeur": "Lamine Benjelloun", "telephone": "0661234545", "statut": "en_port"},
    {"plaque": "MA-4659-T", "chauffeur": "Amir Tazi", "telephone": "0661234546", "statut": "sorti"},
    {"plaque": "MA-4760-U", "chauffeur": "Hamid Benali", "telephone": "0661234547", "statut": "en_attente"},
    {"plaque": "MA-4861-V", "chauffeur": "Kamal Rifai", "telephone": "0661234548", "statut": "en_port"},
    {"plaque": "MA-4962-W", "chauffeur": "Nour Eddine Fassi", "telephone": "0661234549", "statut": "sorti"},
    {"plaque": "MA-5063-X", "chauffeur": "Achraf Benkirane", "telephone": "0661234550", "statut": "en_attente"},
]

for i, truck in enumerate(trucks):
    doc_id = f"camion_{i+1:02d}"
    db.collection("port_med_tanger").document(doc_id).set(truck)
    print(f"✅ {doc_id} - {truck['chauffeur']} | {truck['plaque']} | {truck['statut']}")

print(f"\n🚛 {len(trucks)} camions importés dans Port Med Tanger !")