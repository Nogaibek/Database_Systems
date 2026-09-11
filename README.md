# A Database Systems Laboratory work1\ \ 
<details>
<summary>Part1</summary>  
<details>
<summary>task1.1</summary>  
\
### A Relation A: Employee \
Employee(EmpID, SSN, Email, Phone, Name, Department, Salary)\ \ 

|  EmpID  |  SSN      |  Email         |  Phone   |  Name    |Department|  Salary  |
|---------|-----------|----------------|----------|----------|----------|----------|
|101      |123-45-6789|john@company.com|555-0101  |John      |IT        |75000     |
|102      |987-65-4321|mary@company.com|555-0102  |Mary      |HR        |68000     |
|103      |456-78-9123|bob@company.com |555-0103  |Bob       |IT        |72000     |

\ 

**1. List at least 6 different superkeys**\
SuperKeys: EmpID, SSN, Phone, (EmpID, Salary), (EmpID, Email), (EmpID, SSN, Phone)\ \

**2. Identify	all	candidate	keys**\
Candidate Keys: EmpID, SSN, Phone\ \

**3. Which candidate key would you choose as primary key and why?**\
I choose "EmpID". Because it is short, simple, immutable and invented by us.\ \

**4. Can two employees have the same phone number?**\
No, two employees cannot have the same phone number. Phone numbers are always different. As you can see, the table has a column "EmpID", which means that each employees has a unique ID.\ \

### A Relation B: Course registration \
Registration(StudentID, CourseCode, Section, Semester, Year, Grade, Credits)\ \
Business Rules:\
- A student can take the same course in different semesters \
- A student cannot register for the same course section in the same semester \
- Each course section in a semester has a fixed credit value \ \

**1. List at least 6 different superkeys**\
SuperKeys: EmpID, SSN, Phone, (EmpID, Salary), (EmpID, Email), (EmpID, SSN, Phone)\ \

**2. Identify	all	candidate	keys**\
Candidate Keys: EmpID, SSN, Phone\ \

**3. Which candidate key would you choose as primary key and why?**\
I choose "EmpID". Because it is short, simple, immutable and invented by us.\ \

</details>
</details>