# Database Systems

### Laboratory work1

<details>
<summary>Part 1: Key Identification Exercises</summary>  
<details>
<summary>Task 1.1: Superkey and Candidate Key Analysis</summary>  

### Relation A: Employee
     Employee(EmpID, SSN, Email, Phone, Name, Department, Salary)

|  EmpID  |  SSN      |  Email         |  Phone   |  Name    |Department|  Salary  |
|---------|-----------|----------------|----------|----------|----------|----------|
|101      |123-45-6789|john@company.com|555-0101  |John      |IT        |75000     |
|102      |987-65-4321|mary@company.com|555-0102  |Mary      |HR        |68000     |
|103      |456-78-9123|bob@company.com |555-0103  |Bob       |IT        |72000     |

**1. List at least 6 different superkeys**  \
     SuperKeys: EmpID, SSN, Phone, (EmpID, Salary), (EmpID, Email), (EmpID, SSN, Phone)

**2. Identify	all	candidate	keys**  \
     Candidate Keys: EmpID, SSN, Phone

**3. Which candidate key would you choose as primary key and why?**  \
     I choose "EmpID". Because it is short, simple, immutable and invented by us

**4. Can two employees have the same phone number?**  \
     No, two employees cannot have the same phone number. Phone numbers are always different. As you can see, the table has a column "EmpID", which means that each employees has a unique ID.

### Relation B: Course registration
     Registration(StudentID, CourseCode, Section, Semester, Year, Grade, Credits)

     Business Rules:
          - A student can take the same course in different semesters
          - A student cannot register for the same course section in the same semester
          - Each course section in a semester has a fixed credit value

**1. Determine the minimum attributes needed for the primary key**  \
     Minimum attributes needed for the primary key are (StudentID, CourseCode, Section, Semester, Year)

**2. Explain why each attribute in your primary key is necessary**  \
     StudentID alone is not enough because one student can register for many courses. StudentID + CourseCode is not enough because a student can take the same course in different semesters. Section, Semester ans Year re needed to identify a specific course section in a specific semester

**3. Identify any additional candidate keys**  \
     There are no additional candidate keysbased on the given business rules

</details>
<details>
<summary>Task 1.2: Foreign Key Design</summary>

### Relation C: University system 
     Given Tables:
     Student(StudentID, Name, Email, Major, AdvisorID)
     Professor(ProfID, Name, Department, Salary)
     Course(CourseID, Title, Credits, DepartmentCode)
     Department(DeptCode, DeptName, Budget, ChairID)
     Enrollment(StudentID, CourseID, Semester, Grade)

**1. All foreign key:**  \
Student.AdvisorID -> Professor.ProfID \
Course.DepartmentCode -> Department.DeptCode \
Department.ChairID -> Professor.ProfID \
Enrollment.StudentID -> Student.StudentID \
Enrollment.CourseID -> Course.CourseID

</details>
</details>

<details>
<summary>Part 2: ER Diagram Construction</summary>  
<details>
<summary>Task 2.1: Hospital Management System</summary>

### Relation D: Hospital management system
     Requirements:
     - Patients have unique patient IDs, names, birthdates, addresses	(street, city, state, zip), phone numbers (multiple allowed), and insurance information
     - Doctors have unique doctor IDs, names, specializations (can have multiple), phone numbers, and office locations
     - Departments have department codes, names, and locations
     - Appointments track which patient sees which doctor at what date/time, the purpose of visit, and any notes
     - Prescriptions track medications prescribed by doctors to patients, including dosage and instructions
     - Hospital Rooms are numbered	within departments (room 101 in Cardiology is different from room 101 in Neurology)

**1. Identify all entities** 
- Patient
- Doctor
- Department
- Appointment
- Prescription
- HospitalRoom

**2. Identify all attributes for each entity	(classify	as simple, composite, multi-valued, or derived)**  \
(1) Patient (PatientID(simple), Name(simple), BirthDate(simple), Address(composite), PhoneNumber(multi-valued), Insurance(simple)), where Address consists of (Street, City, State, ZIP) \
(2) Doctor (DoctorID(simple), Name(simple), Specialization(multi-valued), phoneNumber(simple), OfficeLocation(simple)) \
(3) Department (DeptCode(simple), Name(simple), Location(simple)) \
(4) Appointment (AppointmentID, DateTime(simple), Purpose(simple), Notes(simple)) \
(5) Prescription (PrescriptionID, Medication(simple), Dosage(simple), Instructions(simple)) \
(6) HospitalRoom (RoomNumber(simple), DeptCode(simple))

**3. Identify all relationships with their cardinalities (1:1, 1:N, M:N)**  \
Patient 1 - N Appointment \
Doctor 1 - N Appointment \
Doctor 1 - N Prescription \
Patient 1 - N Prescription \
Department 1 - N Doctor \
Department 1 - N HostpitalRoom

**4. Draw the complete ER diagram using proper notation**  \
I drew this in the file "erdplus_pic1.png"

**5. Mark primary keys**  \
Patient -> PatientID \
Doctor -> DoctorID \
Department -> DepartmentCode \
Appointment -> AppointmentID \
Prescription ->PrescriptionID \
HospitalRoom -> (DepartmentCode, RoomNumber)

</details>
<details>
<summary>Task 2.2: E-commerce Platform</summary>

### Relation E: Simplified e-commerce database
     Requirements:
     - "Customers" place "Orders" for "Products"
     - "Products" belong to "Categories" and are supplied by "Vendors"
     - "Orders" contain multiple "Order Items" (quantity and price at time of order)
     - "Products" have reviews and ratings from customers
     - Track "Inventory" levels for each product
     - "Shipping addresses" can be different from customer billing addresses

**1. Create a complete ER diagram**  \
I drew this in the file "erdplus_pic2.png"

**2. Identify at least one weak entity and justify why it’s weak**  \
Weak entity is OrderItem, because it is depends on an Order for it is indentification.

**3. Identify at least one many-to-many relationship that needs attributes**  \
Many-to-many relationship is Product:Order, because one order can contain many products, and one product can appear in many orders.
</details>
</details>

<details>
<summary>Part 3: Normalization Workshop</summary>  
<details>
<summary>Task 3.1: Denormalized Table Analysis</summary>

### Given table
     StudentProject(StudentID, StudentName, StudentMajor, ProjectID, 
                    ProjectTitle, ProjectType, SupervisorID, SupervisorName, 
                    SupervisorDept, Role, HoursWorked, StartDate, EndDate)

**1. Identify functional dependencies** \
(1) StudentID -> StudentName, StudentMajor \
(2) ProjectID -> ProjectTitle, ProjectType, SupervisorID, StartDate, EndDate \
(3) SupervisorID -> SupervisorName, SupervisorDept \
(4) (StudentID, ProjectID) -> Role, HoursWorked 

**2. Identify problems: -What redundancy exists in this table? - Give specific examples of update, insert, and delete anomalies** \
(1) The table contains redundant student, project, and supervisor information. \
(2) Update anomaly: changing a supervisor's department requires updating many rows. \
(3) Insert anomaly: a new project cannot be easily inserted without a student. \
(4) Delete anomaly: deleting the last student from a project may also delete project information. 

**3. Apply 1NF: Are there any 1NF violations? How would you fix them?** \
There are no 1NF violations, assuming all attributes contain atomic values.

**4. Apply 2NF: -What is the primary key of this table? -Identify any partial dependencies -Show the 2NF decomposition** \
Primary key: (StudentID, ProjectID).  
Partial dependencies:  
     (1) StudentID → StudentName, StudentMajor  
     (2) ProjectID → ProjectTitle, ProjectType, SupervisorID, StartDate, EndDate  
  
- Student(StudentID, StudentName, StudentMajor)
- Project(ProjectID, ProjectTitle, ProjectType,
        SupervisorID, SupervisorName, SupervisorDept,
        StartDate, EndDate)
- StudentProject(StudentID, ProjectID, Role, HoursWorked)

**5. Apply 3NF: -Identify any transitive dependencies -Show the final 3NF decomposition with all table schemas** \
Transitive dependency: ProjectID → SupervisorID → SupervisorName, SupervisorDept
- Student(StudentID, StudentName, StudentMajor)
- Supervisor(SupervisorID, SupervisorName, SupervisorDept)
- Project(ProjectID, ProjectTitle, ProjectType,
        SupervisorID, StartDate, EndDate)
- StudentProject(StudentID, ProjectID, Role, HoursWorked)

</details>
<details>
<summary>Task 3.2: Advanced Normalization</summary>

### Given table
     CourseSchedule(StudentID, StudentMajor, CourseID, CourseName,
                    InstructorID, InstructorName, TimeSlot, Room, Building)
     Business Rules:
     - Each student has exactly one major
     - Each course has a fixed name
     - Each instructor has exactly one name
     - Each time slot in a room determines the building (rooms are unique across campus)
     - Each course section is taught by one instructor at one time in one room
     - A student can be enrolled in multiple course sections

**1. Determine the primary key of this table (hint: this is tricky!)** \
Primary key (StudentID, CourseID). Because StudentID detemines room, timeSlot, instructor

**2. List all functional dependencies** \
if we know StudentID, we know StudentMajor \
if we know CourseID, we know CourseName, InstructorID, TimeSlot, Room \
if we know InstructorID, we know InstructorName \
if we know TimeSlot and Room, we know Building

**3. Check if the table is in BCNF** \
No, the table is not in BCNF. The primary key is (StudentID, CourseID). However, StudentID, CourseID, InstructorID, and (TimeSlot, Room) are not superkeys of the original relation, while they determine other attributes. Therefore, the table violates BCNF.

**4. If not in BCNF, decompose it to BCNF showing your work** \
Student(StudentID, StudentMajor) \
Course(CourseID, CourseName, InstructorID, TimeSlot, Room) \
Instructor(InstructorID, InstructorName) \
RoomSchedule(TimeSlot, Room, Building) \
Enrollment(StudentID, CourseID) 

**5. Explain any potential loss of information in your decomposition** \
The decomposition is lossless as long as the tables are joined using their common attributes (StudentID, CourseID, and TimeSlot + Room). No information is lost because all original attributes can be reconstructed from the decomposed relations.

</details>
</details>

<details>
<summary>Part 4: Design Challenge</summary>  
<details>
<summary>Task 4.1: Real-World Application</summary>

### Scenario: Your university wants to track student clubs and organizations with the following requirements:
     System Requirements:
     - Student clubs and organizations information
     - Club membership (students can join multiple clubs, clubs have multiple members)
     - Club events and student attendance tracking
     - Club officer positions (president, treasurer, secretary, etc.)
     - Faculty advisors for clubs (each club has one advisor, faculty can advise multiple clubs)
     - Room reservations for club events
     - Club budget and expense tracking

**1. Create a complete ER diagram for this system** \
I drew this in the file "erdplus_pic3.png"

**2. Convert your ER diagram to a normalized relational schema** \
(1) Student (StudentID PK, Name, Email) \
(2) Faculty (FacultyID PK, Name, Department) \
(3) Club (ClubID PK, ClubName, Description, AdvisorID FK) \
(4) Membership (StudentID PK/FK, ClubID PK/FK, JoinDate) \
(5) Attendance (EventID PK/FK, StudentID PK/FK, AttendanceStatus) \
(6) OfficerPosition (PositionID PK, PositionName) \
(7) ClubOfficer (ClubID PK/FK, StudentID PK/FK, PositionID FK, StartDate, EndDate) \
(8) Room (RoomID PK, Building, RoomNumber, Capacity) \
(9) Reservation (ReservationID PK, EventID FK, RoomID FK, StartDateTime, EndDateTime) \
(10) Budget (BudgetID PK, ClubID FK, Amount, FiscalYear) \
(11) Expense (ExpenseID PK, ClubID FK, Amount, ExpenseDate,Description)

**3. Identify at least one design decision where you had multiple valid options and explain your choice** \
I chose to store officer positions in a separate table because it avoids repeating the same position names and makes it easier to add new positions later. "OfficerPosition (PositionID PK, PositionName)"

**4. Write 3 example queries that your database should support (in English, not SQL)** \
Query 1: List all students who are members of a particular club. \
Query 2: Show all upcoming events for a particular club and the rooms reserved for them. \
Query 3: Find all club expenses for a given year and calculate the total amount spent by each club.

<details>
<details>