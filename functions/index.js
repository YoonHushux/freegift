const {onRequest} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const xlsx = require("xlsx");

// Initialize Firebase Admin
admin.initializeApp();

// Function to clean customer ID for use as Firestore document ID
function cleanCustomerId(id) {
  if (!id) return null;
  
  // Convert to string and clean
  let cleanId = String(id).trim();
  
  // Remove or replace invalid characters for Firestore document IDs
  // Firestore document IDs cannot contain: / \ [ ] * ? < > | ` and control characters
  cleanId = cleanId.replace(/[\/\\[\]*?<>|`\x00-\x1f\x7f]/g, '_');
  
  // Remove leading/trailing dots and spaces
  cleanId = cleanId.replace(/^[.\s]+|[.\s]+$/g, '');
  
  // If empty after cleaning, return null
  if (!cleanId || cleanId.length === 0) return null;
  
  // Ensure it's not too long (Firestore limit is 1500 characters)
  if (cleanId.length > 100) {
    cleanId = cleanId.substring(0, 100);
  }
  
  return cleanId;
}

// HTTP function to process Excel files and import customer data
exports.processCustomerExcel = onRequest({
  region: 'asia-southeast1',
  cors: true,
}, async (req, res) => {
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  try {
    const { fileName } = req.body;
    if (!fileName) {
      res.status(400).json({ error: 'fileName is required' });
      return;
    }

    console.log(`Processing customer Excel file: ${fileName}`);
    console.log(`Request body:`, req.body);
    
    const bucket = admin.storage().bucket();
    const filePath = `customers/${fileName}`;
    
    // Check if file exists first
    const fileExists = await bucket.file(filePath).exists();
    if (!fileExists[0]) {
      console.error(`File not found: ${filePath}`);
      res.status(404).json({ error: 'File not found', filePath: filePath });
      return;
    }
    
    // Download the file from Storage
    const tempFilePath = `/tmp/${fileName}`;
    await bucket.file(filePath).download({ destination: tempFilePath });
    
    // Read Excel file
    const workbook = xlsx.readFile(tempFilePath);
    const sheetName = workbook.SheetNames[0]; // Use first sheet
    const worksheet = workbook.Sheets[sheetName];
    const jsonData = xlsx.utils.sheet_to_json(worksheet);
    
    console.log(`Found ${jsonData.length} rows in Excel file`);
    
    // Process each row and import to Firestore
    const db = admin.firestore();
    const batch = db.batch();
    let processedCount = 0;
    
    for (const row of jsonData) {
      // Extract customer ID and name (adjust column names as needed)
      const rawCustomerId = row['รหัสลูกค้า'] || row['ID'] || row['id'] || row['customer_id'];
      const customerName = row['ชื่อลูกค้า'] || row['Name'] || row['name'] || row['customer_name'];
      
      // Clean the customer ID for Firestore
      const customerId = cleanCustomerId(rawCustomerId);
      
      console.log(`Processing row - Raw ID: "${rawCustomerId}", Clean ID: "${customerId}", Name: "${customerName}"`);
      
      if (customerId && customerName && String(customerName).trim()) {
        const customerRef = db.collection('customers').doc(customerId);
        batch.set(customerRef, {
          id: customerId,
          originalId: String(rawCustomerId), // Keep original ID for reference
          name: String(customerName).trim(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          importedFrom: fileName
        }, { merge: true }); // merge: true will overwrite existing data
        
        processedCount++;
      } else {
        console.log(`Skipping invalid row - Raw ID: "${rawCustomerId}", Clean ID: "${customerId}", Name: "${customerName}"`);
      }
    }
    
    // Commit the batch
    await batch.commit();
    
    console.log(`Successfully imported ${processedCount} customers to Firestore`);
    
    // Optionally, you can move the processed file to a 'processed' folder
    const processedPath = `customers/processed/${fileName}`;
    await bucket.file(filePath).move(processedPath);
    
    res.json({ success: true, processed: processedCount });
    
  } catch (error) {
    console.error('Error processing Excel file:', error);
    res.status(500).json({ error: 'Failed to process Excel file', details: error.message });
  }
});

// HTTP function to manually trigger Excel processing (for testing)
exports.uploadCustomerExcel = onRequest({
  region: 'asia-southeast1',
}, async (req, res) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Content-Type');
  
  if (req.method === 'OPTIONS') {
    res.status(200).send();
    return;
  }
  
  try {
    const db = admin.firestore();
    const customersSnapshot = await db.collection('customers').get();
    const customers = [];
    
    customersSnapshot.forEach(doc => {
      customers.push({ id: doc.id, ...doc.data() });
    });
    
    res.json({ 
      success: true, 
      message: 'Customer data retrieved successfully',
      customers: customers 
    });
  } catch (error) {
    console.error('Error retrieving customers:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

exports.myFunction = onRequest({
  region: 'asia-southeast1',
}, (req, res) => {
  res.send("Hello World");
});
