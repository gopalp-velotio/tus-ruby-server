# File Upload API Documentation

A clean, API-only Rails application for resumable file uploads using the tus protocol.

## 🚀 Quick Start

```bash
cd tus-api
bundle install
bin/rails db:create
bin/rails db:migrate
bin/rails server
```

The API will be available at `http://localhost:3000`

## 📋 API Endpoints

### Base URL: `http://localhost:3000/api`

---

## 1. Simple File Upload
**For files smaller than 50MB**

**Endpoint:** `POST /api/upload`

**Headers:**
```
Content-Type: multipart/form-data
```

**Body (FormData):**
- `file`: (required) The file to upload
- `filename`: (optional) Custom filename

**Example (JavaScript):**
```javascript
const formData = new FormData();
formData.append('file', fileInput.files[0]);
formData.append('filename', 'my_custom_name.jpg'); // optional

fetch('http://localhost:3000/api/upload', {
  method: 'POST',
  body: formData
})
.then(res => res.json())
.then(console.log);
```

**Success Response:**
```json
{
  "success": true,
  "message": "File uploaded successfully",
  "file_id": "abc123def456",
  "filename": "myfile.jpg",
  "size": 1048576
}
```

---

## 2. Chunked Upload (For Large Files)

### Step 1: Create Upload Session
**Endpoint:** `POST /api/upload/session`

**Headers:**
```
Content-Type: application/json
```

**Body:**
```json
{
  "filename": "large-file.zip",
  "file_size": 104857600
}
```

**Success Response:**
```json
{
  "success": true,
  "upload_id": "abc123def456",
  "upload_url": "/files/abc123def456",
  "chunk_size": 5242880
}
```

---

### Step 2: Upload Chunks
**Endpoint:** `POST /api/upload/chunk`

**Headers:**
```
Content-Type: multipart/form-data
```

**Body (FormData):**
- `chunk`: (required) The file chunk (use Blob/File.slice)
- `upload_id`: (required) The upload ID from previous step
- `offset`: (required) The starting byte offset for this chunk

**Example (JavaScript):**
```javascript
const chunkSize = 5 * 1024 * 1024; // 5MB
let offset = 0;

async function uploadChunks(file, uploadId) {
  while (offset < file.size) {
    const chunk = file.slice(offset, offset + chunkSize);
    const formData = new FormData();
    formData.append('chunk', chunk);
    formData.append('upload_id', uploadId);
    formData.append('offset', offset);

    const res = await fetch('http://localhost:3000/api/upload/chunk', {
      method: 'POST',
      body: formData
    });
    const result = await res.json();
    if (result.success) {
      offset = result.offset;
      if (result.completed) break;
    } else {
      throw new Error(result.error);
    }
  }
}
```

**Success Response:**
```json
{
  "success": true,
  "offset": 5242880,
  "completed": false
}
```

---

### Step 3: Check Upload Status
**Endpoint:** `GET /api/upload/status/:upload_id`

**Example:** `GET /api/upload/status/abc123def456`

**Success Response:**
```json
{
  "success": true,
  "upload_id": "abc123def456",
  "offset": 10485760,
  "length": 104857600,
  "completed": false,
  "progress": 10.0
}
```

---

## 3. List Uploaded Files
**Endpoint:** `GET /api/files`

**Success Response:**
```json
{
  "success": true,
  "files": [
    {
      "id": "abc123def456",
      "filename": "myfile.jpg",
      "size": 1048576,
      "created_at": "2024-01-15T10:30:00Z",
      "upload_length": "1048576",
      "upload_offset": "1048576"
    }
  ],
  "count": 1
}
```

---

## 4. Direct Tus Protocol Endpoints

For advanced users who want to use the tus protocol directly:

- `POST /files` - Create upload
- `PATCH /files/:upload_id` - Upload chunks
- `HEAD /files/:upload_id` - Check status
- `DELETE /files/:upload_id` - Delete upload

---

## 📊 Quick Reference Table

| Method | Endpoint                        | Purpose                | Content-Type           |
|--------|---------------------------------|------------------------|------------------------|
| POST   | /api/upload                     | Simple upload          | multipart/form-data    |
| POST   | /api/upload/session             | Create session         | application/json       |
| POST   | /api/upload/chunk               | Upload chunk           | multipart/form-data    |
| GET    | /api/upload/status/:upload_id   | Check upload status    | -                      |
| GET    | /api/files                      | List uploaded files    | -                      |

---

## ⚠️ Error Responses

All endpoints return errors in this format:
```json
{
  "error": "Error message here"
}
```

Common error scenarios:
- `File too large. Maximum size is 10GB`
- `No file provided`
- `Missing chunk data or upload ID`
- `Invalid filename or file size`
- `Upload not found`

---

## 📦 File Limits

- **Max file size:** 10GB
- **Chunk size:** 5MB (automatic)
- **Simple upload:** < 50MB recommended
- **Chunked upload:** > 50MB recommended

---

## 🌍 CORS Support

All endpoints support CORS and can be called from any frontend application.

---

## 🔧 Configuration

### Environment Variables

Create a `.env` file in the project root:

```bash
# Frontend URL for CORS
FRONTEND_URL=http://localhost:3000

# Database configuration
TUS_API_DATABASE_PASSWORD=your-database-password

# Rails configuration
RAILS_MASTER_KEY=your-rails-master-key
```

### File Storage

Files are stored in:
- **Location:** `storage/uploads/`
- **Permissions:** 0644 (readable by owner and group)
- **Expiration:** 24 hours (configurable)
- **Cleanup:** Every hour (configurable)

---

## 🧪 Testing

### Using cURL

**Simple Upload:**
```bash
curl -X POST http://localhost:3000/api/upload \
  -F "file=@/path/to/your/file.jpg" \
  -F "filename=test.jpg"
```

**Create Session:**
```bash
curl -X POST http://localhost:3000/api/upload/session \
  -H "Content-Type: application/json" \
  -d '{"filename":"test.txt","file_size":100}'
```

**List Files:**
```bash
curl http://localhost:3000/api/files
```

### Using JavaScript

```javascript
class FileUploader {
  constructor(baseUrl = 'http://localhost:3000/api') {
    this.baseUrl = baseUrl;
    this.chunkSize = 5 * 1024 * 1024; // 5MB
  }

  // Simple upload for small files
  async uploadFile(file, customFilename = null) {
    const formData = new FormData();
    formData.append('file', file);
    if (customFilename) {
      formData.append('filename', customFilename);
    }

    const response = await fetch(`${this.baseUrl}/upload`, {
      method: 'POST',
      body: formData
    });

    return await response.json();
  }

  // Chunked upload for large files
  async uploadLargeFile(file, onProgress = null) {
    try {
      // Step 1: Create upload session
      const sessionResponse = await fetch(`${this.baseUrl}/upload/session`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          filename: file.name,
          file_size: file.size
        })
      });

      const sessionData = await sessionResponse.json();
      
      if (!sessionData.success) {
        throw new Error(sessionData.error);
      }

      const uploadId = sessionData.upload_id;
      let offset = 0;

      // Step 2: Upload chunks
      while (offset < file.size) {
        const chunk = file.slice(offset, offset + this.chunkSize);
        
        const formData = new FormData();
        formData.append('chunk', chunk);
        formData.append('upload_id', uploadId);
        formData.append('offset', offset);

        const chunkResponse = await fetch(`${this.baseUrl}/upload/chunk`, {
          method: 'POST',
          body: formData
        });

        const chunkData = await chunkResponse.json();
        
        if (!chunkData.success) {
          throw new Error(chunkData.error);
        }

        offset = chunkData.offset;
        
        // Call progress callback
        if (onProgress) {
          const progress = (offset / file.size) * 100;
          onProgress(progress, offset, file.size);
        }

        if (chunkData.completed) {
          return {
            success: true,
            upload_id: uploadId,
            filename: file.name,
            size: file.size
          };
        }
      }

    } catch (error) {
      return {
        success: false,
        error: error.message
      };
    }
  }

  // Check upload status
  async getUploadStatus(uploadId) {
    const response = await fetch(`${this.baseUrl}/upload/status/${uploadId}`);
    return await response.json();
  }

  // List uploaded files
  async listFiles() {
    const response = await fetch(`${this.baseUrl}/files`);
    return await response.json();
  }
}

// Usage
const uploader = new FileUploader();

// Simple upload
document.getElementById('fileInput').addEventListener('change', async (e) => {
  const file = e.target.files[0];
  
  if (file.size < 50 * 1024 * 1024) { // Less than 50MB
    const result = await uploader.uploadFile(file);
    console.log('Upload result:', result);
  } else {
    // Large file upload with progress
    const result = await uploader.uploadLargeFile(file, (progress, uploaded, total) => {
      console.log(`Progress: ${progress.toFixed(2)}%`);
    });
    
    console.log('Upload result:', result);
  }
});
```

---

## 🚀 Production Deployment

1. Set environment variables
2. Configure database
3. Set up proper file storage (consider cloud storage)
4. Configure CORS for your frontend domain
5. Set up monitoring and logging

---

## 📝 License

This project is open source and available under the MIT License. 