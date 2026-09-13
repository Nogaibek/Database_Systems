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
1. Student.AdvisorID → Professor.ProfID
2. Course.DepartmentCode → Department.DeptCode
3. Department.ChairID → Professor.ProfID
4. Enrollment.StudentID → Student.StudentID
5. Enrollment.CourseID → Course.CourseID

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

**1. Identify all entities**  \

**2. Identify all attributes for each entity	(classify	as simple, composite, multi-valued, or derived)**  \

**3. Identify all relationships with their cardinalities (1:1, 1:N, M:N)**  \

**4. Draw the complete ER diagram using proper notation**  \

**5. Mark primary keys**  \

</details>
<details>
<summary>Task 2.2: E-commerce Platform</summary>

### Relation D: Simplified e-commerce database
     Requirements:
     - "Customers" place "Orders" for "Products"
     - "Products" belong to "Categories" and are supplied by "Vendors"
     - "Orders" contain multiple "Order Items" (quantity and price at time of order)
     - "Products" have reviews and ratings from customers
     - Track "Inventory" levels for each product
     - "Shipping addresses" can be different from customer billing addresses

**1. Create a complete ER diagram**  \

**2. Identify at least one weak entity and justify why it’s weak**  \

**3. Identify at least one many-to-many relationship that needs attributes**  \

</details>
</details> 