// Node.js script to generate diagram images using Mermaid CLI
// Run: node generate_diagrams.js

const { exec } = require('child_process');
const fs = require('fs');

const diagrams = [
    {
        name: 'use-case-diagram',
        mermaid: `graph TB
    Admin[Admin User]
    Staff[Staff User]
    
    Admin --> UC1[Manage Users]
    Admin --> UC2[Create Distribution Program]
    Admin --> UC3[View All Beneficiaries]
    Admin --> UC4[View Reports & Analytics]
    Admin --> UC5[Export Data]
    Admin --> UC6[Update Program Status]
    Admin --> UC7[Delete Beneficiaries]
    
    Staff --> UC8[Register Beneficiary]
    Staff --> UC9[View Own Beneficiaries]
    Staff --> UC10[Distribute Aid]
    Staff --> UC11[View Distribution Programs]
    
    UC1 --> UC1a[Create Staff Account]
    UC1 --> UC1b[Update User Status]
    UC1 --> UC1c[Delete User]
    
    UC2 --> UC2a[Set Target Categories]
    UC2 --> UC2b[Set Aid Type & Quantity]
    UC2 --> UC2c[Set Budget & Limits]
    
    UC8 --> UC8a[Capture Photo]
    UC8 --> UC8b[Capture GPS Location]
    UC8 --> UC8c[Select Vulnerable Categories]
    UC8 --> UC8d[Calculate Urgency Score]
    
    UC10 --> UC10a[Check Double Distribution]
    UC10 --> UC10b[Record Distribution]
    UC10 --> UC10c[Update Program Counters]
    
    UC4 --> UC4a[View Statistics]
    UC4 --> UC4b[View Category Breakdown]
    UC4 --> UC4c[View Aid Type Breakdown]
    
    style Admin fill:#4A90E2,color:#fff
    style Staff fill:#50C878,color:#fff
    style UC1 fill:#FFD700
    style UC2 fill:#FFD700
    style UC8 fill:#50C878
    style UC10 fill:#50C878`
    },
    {
        name: 'sequence-beneficiary-registration',
        mermaid: `sequenceDiagram
    participant Staff
    participant RegistrationScreen
    participant CloudinaryService
    participant BeneficiaryService
    participant Firestore
    participant BeneficiaryListScreen
    
    Staff->>RegistrationScreen: Fill Form & Submit
    RegistrationScreen->>RegistrationScreen: Validate Form
    alt Photo Provided
        RegistrationScreen->>CloudinaryService: Upload Photo
        CloudinaryService->>CloudinaryService: Compress Image
        CloudinaryService-->>RegistrationScreen: Return Photo URL
    end
    RegistrationScreen->>RegistrationScreen: Calculate Urgency Score
    RegistrationScreen->>BeneficiaryService: createBeneficiary()
    BeneficiaryService->>Firestore: Check National ID Exists
    Firestore-->>BeneficiaryService: Return Result
    alt National ID Already Exists
        BeneficiaryService-->>RegistrationScreen: Error: ID Exists
        RegistrationScreen-->>Staff: Show Error Message
    else National ID Available
        BeneficiaryService->>Firestore: Create Beneficiary Document
        Firestore-->>BeneficiaryService: Return Document ID
        BeneficiaryService-->>RegistrationScreen: Success
        RegistrationScreen->>BeneficiaryListScreen: Navigate
        BeneficiaryListScreen->>Firestore: Query Beneficiaries
        Firestore-->>BeneficiaryListScreen: Return List
        BeneficiaryListScreen-->>Staff: Display Beneficiaries
    end`
    },
    {
        name: 'sequence-distribution-flow',
        mermaid: `sequenceDiagram
    participant Staff
    participant ProgramDetailScreen
    participant DistributeAidScreen
    participant DistributionService
    participant Firestore
    participant ProgramService
    
    Staff->>ProgramDetailScreen: Click "Distribute" Button
    ProgramDetailScreen->>DistributeAidScreen: Navigate with Beneficiary & Program
    DistributeAidScreen->>DistributionService: hasAlreadyReceived()
    DistributionService->>Firestore: Query distribution_records<br/>WHERE programId=X AND beneficiaryId=Y
    Firestore-->>DistributionService: Return Result
    alt Already Received
        DistributionService-->>DistributeAidScreen: true
        DistributeAidScreen-->>Staff: Show Warning: Already Received
    else Not Received
        DistributionService-->>DistributeAidScreen: false
        Staff->>DistributeAidScreen: Confirm Distribution
        DistributeAidScreen->>DistributionService: recordDistribution()
        DistributionService->>Firestore: Create DistributionRecord
        Firestore-->>DistributionService: Success
        DistributionService->>ProgramService: Update Program Counters
        ProgramService->>Firestore: Increment distributedCount<br/>Increment distributedQuantity
        Firestore-->>ProgramService: Success
        ProgramService-->>DistributionService: Success
        DistributionService-->>DistributeAidScreen: Success
        DistributeAidScreen-->>Staff: Show Success Message
    end`
    },
    {
        name: 'er-diagram',
        mermaid: `erDiagram
    USER ||--o{ BENEFICIARY : "registers"
    USER ||--o{ DISTRIBUTION_PROGRAM : "creates"
    USER ||--o{ DISTRIBUTION_RECORD : "distributes"
    DISTRIBUTION_PROGRAM ||--o{ DISTRIBUTION_RECORD : "has"
    BENEFICIARY ||--o{ DISTRIBUTION_RECORD : "receives"
    
    USER {
        string uid PK
        string email UK
        string fullName
        string phone
        string role "admin|staff"
        boolean isActive
        datetime createdAt
    }
    
    BENEFICIARY {
        string beneficiaryId PK
        string nationalId UK
        string fullName
        string phoneNumber
        int age
        string gender
        array vulnerableCategories
        int childrenUnder5Count
        array childrenAges
        int totalFamilySize
        boolean isFemaleHeadedHousehold
        string incomeLevel
        boolean currentlyReceivingOtherAid
        string region
        string zone
        string woreda
        double latitude
        double longitude
        string photoUrl "Cloudinary URL"
        double urgencyScore
        string registeredBy FK
        datetime createdAt
        datetime updatedAt
    }
    
    DISTRIBUTION_PROGRAM {
        string programId PK
        string programName
        string description
        string aidType
        array targetCategories
        double quantityPerBeneficiary
        string unit
        double totalBudget
        int maxBeneficiaries
        datetime startDate
        datetime endDate
        string status "draft|active|paused|completed|cancelled"
        string region
        string createdBy FK
        int distributedCount
        double distributedQuantity
        datetime createdAt
        datetime updatedAt
    }
    
    DISTRIBUTION_RECORD {
        string recordId PK
        string programId FK
        string beneficiaryId FK
        string beneficiaryName "denormalized"
        string beneficiaryNationalId "denormalized"
        string aidType
        double quantity
        string unit
        string distributedBy FK
        string distributedByName "denormalized"
        datetime distributedAt
        double latitude
        double longitude
        string notes
    }`
    },
    {
        name: 'class-diagram',
        mermaid: `classDiagram
    class UserModel {
        +String uid
        +String email
        +String fullName
        +String phone
        +String role
        +bool isActive
        +DateTime createdAt
        +fromFirestore(DocumentSnapshot)
        +toMap()
    }
    
    class BeneficiaryModel {
        +String beneficiaryId
        +String fullName
        +String nationalId
        +String? phoneNumber
        +int? age
        +String gender
        +List~String~ vulnerableCategories
        +bool isPregnant
        +int? pregnancyTrimester
        +int childrenUnder5Count
        +List~int~ childrenAges
        +int totalFamilySize
        +bool isFemaleHeadedHousehold
        +String incomeLevel
        +bool currentlyReceivingOtherAid
        +String region
        +String? zone
        +String? woreda
        +double? latitude
        +double? longitude
        +String? photoUrl
        +double urgencyScore
        +String registeredBy
        +DateTime createdAt
        +DateTime? updatedAt
        +fromFirestore(DocumentSnapshot)
        +toMap()
        +calculateUrgencyScore()$ double
        +hasCategory(VulnerableCategory) bool
    }
    
    class DistributionProgram {
        +String programId
        +String programName
        +String? description
        +String aidType
        +List~String~ targetCategories
        +double quantityPerBeneficiary
        +String unit
        +double? totalBudget
        +int? maxBeneficiaries
        +DateTime startDate
        +DateTime? endDate
        +String status
        +String? region
        +String createdBy
        +int distributedCount
        +double distributedQuantity
        +DateTime createdAt
        +DateTime? updatedAt
        +fromFirestore(DocumentSnapshot)
        +toMap()
        +isActive bool
    }
    
    class DistributionRecord {
        +String recordId
        +String programId
        +String programName
        +String beneficiaryId
        +String beneficiaryName
        +String beneficiaryNationalId
        +String aidType
        +double quantity
        +String unit
        +String distributedBy
        +String? distributedByName
        +DateTime distributedAt
        +double? latitude
        +double? longitude
        +String? notes
        +fromFirestore(DocumentSnapshot)
        +toMap()
    }
    
    class AuthService {
        -FirebaseAuth _auth
        -FirebaseFirestore _firestore
        +signInWithEmailPassword(String, String) Future~UserModel?~
        +signOut() Future~void~
        +createUser(...) Future~UserModel?~
        +getCurrentUserData() Future~UserModel?~
        +authStateChanges Stream~User?~
    }
    
    class BeneficiaryService {
        -FirebaseFirestore _firestore
        +createBeneficiary(BeneficiaryModel) Future~String?~
        +getAllBeneficiaries() Stream~List~BeneficiaryModel~~
        +getBeneficiariesByStaff(String) Stream~List~BeneficiaryModel~~
        +getBeneficiaryById(String) Future~BeneficiaryModel?~
        +searchBeneficiaries(String) Future~List~BeneficiaryModel~~
        +updateBeneficiary(String, BeneficiaryModel) Future~bool~
        +deleteBeneficiary(String) Future~bool~
        +getBeneficiaryStatistics() Future~Map~String,int~~
    }
    
    class DistributionService {
        -FirebaseFirestore _firestore
        +createProgram(DistributionProgram) Future~String?~
        +getAllPrograms() Stream~List~DistributionProgram~~
        +getActivePrograms() Stream~List~DistributionProgram~~
        +getProgramById(String) Future~DistributionProgram?~
        +updateProgramStatus(String, String) Future~bool~
        +getEligibleBeneficiaries(DistributionProgram) Future~List~BeneficiaryModel~~
        +hasAlreadyReceived(String, String) Future~bool~
        +recordDistribution(DistributionRecord) Future~String?~
        +getDistributionsByProgram(String) Stream~List~DistributionRecord~~
        +getDistributionsByBeneficiary(String) Stream~List~DistributionRecord~~
        +getDistributionStatistics() Future~Map~String,dynamic~~
    }
    
    class CloudinaryService {
        -String _cloudName
        -String _apiKey
        -String _apiSecret
        +uploadBeneficiaryPhoto(File) Future~String~
        -_compressImage(File) Future~File~
        +getOptimizedUrl(String, int) String
    }
    
    class ExportService {
        +exportBeneficiariesToCsv(List~BeneficiaryModel~) Future~String?~
        +exportDistributionsToCsv(List~DistributionRecord~) Future~String?~
        +exportProgramSummary(...) Future~String?~
    }
    
    class FirestoreService {
        -FirebaseFirestore _firestore
        +getAllUsers() Stream~List~UserModel~~
        +getUserById(String) Future~UserModel?~
        +updateUser(String, Map) Future~bool~
        +toggleUserStatus(String) Future~bool~
        +deleteUser(String) Future~bool~
        +getUserStatistics() Future~Map~String,int~~
    }
    
    AuthService --> UserModel : creates/returns
    BeneficiaryService --> BeneficiaryModel : manages
    DistributionService --> DistributionProgram : manages
    DistributionService --> DistributionRecord : manages
    DistributionService --> BeneficiaryModel : queries
    CloudinaryService --> BeneficiaryModel : uploads photos for
    ExportService --> BeneficiaryModel : exports
    ExportService --> DistributionRecord : exports
    FirestoreService --> UserModel : manages`
    },
    {
        name: 'component-diagram',
        mermaid: `graph TB
    subgraph "Presentation Layer"
        A1[LoginScreen]
        A2[AdminDashboard]
        A3[StaffDashboard]
        A4[BeneficiaryRegistrationScreen]
        A5[BeneficiaryListScreen]
        A6[BeneficiaryDetailScreen]
        A7[DistributionProgramsScreen]
        A8[CreateProgramScreen]
        A9[ProgramDetailScreen]
        A10[DistributeAidScreen]
        A11[ReportsDashboardScreen]
        A12[UserManagementScreen]
    end
    
    subgraph "State Management (Riverpod)"
        B1[AuthProvider]
        B2[BeneficiaryProvider]
        B3[DistributionProvider]
        B4[FirestoreProvider]
    end
    
    subgraph "Application Services"
        C1[AuthService]
        C2[BeneficiaryService]
        C3[DistributionService]
        C4[FirestoreService]
        C5[CloudinaryService]
        C6[ExportService]
    end
    
    subgraph "External Services"
        D1[Firebase Auth]
        D2[Firestore]
        D3[Cloudinary API]
    end
    
    A1 --> B1
    A2 --> B1
    A2 --> B4
    A3 --> B1
    A3 --> B2
    A4 --> B2
    A5 --> B2
    A6 --> B2
    A7 --> B3
    A8 --> B3
    A9 --> B3
    A10 --> B3
    A11 --> B3
    A12 --> B4
    
    B1 --> C1
    B2 --> C2
    B2 --> C5
    B3 --> C3
    B4 --> C4
    A11 --> C6
    
    C1 --> D1
    C1 --> D2
    C2 --> D2
    C3 --> D2
    C4 --> D2
    C5 --> D3`
    },
    {
        name: 'data-flow-diagram',
        mermaid: `flowchart TD
    Start([User Action]) --> Auth{Authenticated?}
    Auth -->|No| Login[Login Screen]
    Auth -->|Yes| Role{User Role?}
    
    Role -->|Admin| AdminFlow[Admin Flow]
    Role -->|Staff| StaffFlow[Staff Flow]
    
    AdminFlow --> Admin1[Manage Users]
    AdminFlow --> Admin2[Create Programs]
    AdminFlow --> Admin3[View All Beneficiaries]
    AdminFlow --> Admin4[View Reports]
    AdminFlow --> Admin5[Export Data]
    
    StaffFlow --> Staff1[Register Beneficiary]
    StaffFlow --> Staff2[View Own Beneficiaries]
    StaffFlow --> Staff3[Distribute Aid]
    
    Staff1 --> Photo{Photo?}
    Photo -->|Yes| Cloudinary[Upload to Cloudinary]
    Photo -->|No| Save[Save to Firestore]
    Cloudinary --> Save
    
    Staff3 --> Check{Already Received?}
    Check -->|Yes| Block[Block Distribution]
    Check -->|No| Record[Record Distribution]
    Record --> Update[Update Program Counters]
    
    Admin2 --> Validate[Validate Program]
    Validate --> Create[Create Program in Firestore]
    
    Admin4 --> Query[Query Statistics]
    Query --> Display[Display Dashboard]
    
    Admin5 --> Export[Generate CSV]
    Export --> File[Save to File System]`
    },
    {
        name: 'architecture-diagram',
        mermaid: `graph TB
    subgraph "Mobile App (Flutter)"
        A[Presentation Layer<br/>Screens & Widgets]
        B[State Management<br/>Riverpod Providers]
        C[Business Logic<br/>Services]
    end
    
    subgraph "Backend Services"
        D[Firebase Authentication]
        E[Firestore Database]
        F[Cloudinary Storage]
    end
    
    A --> B
    B --> C
    C --> D
    C --> E
    C --> F
    
    style A fill:#E3F2FD
    style B fill:#F3E5F5
    style C fill:#E8F5E9
    style D fill:#FFF3E0
    style E fill:#FFF3E0
    style F fill:#FFF3E0`
    }
];

// Create diagrams directory
if (!fs.existsSync('diagrams')) {
    fs.mkdirSync('diagrams');
}

// Generate each diagram
diagrams.forEach((diagram, index) => {
    const filename = `diagrams/${diagram.name}.mmd`;
    fs.writeFileSync(filename, diagram.mermaid);
    console.log(`Created: ${filename}`);
});

console.log('\n✅ All diagram files created in /diagrams folder!');
console.log('\nTo generate PNG images, run:');
console.log('npm install -g @mermaid-js/mermaid-cli');
console.log('mmdc -i diagrams/use-case-diagram.mmd -o diagrams/use-case-diagram.png');


