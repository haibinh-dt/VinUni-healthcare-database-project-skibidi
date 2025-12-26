@echo off
setlocal enabledelayedexpansion

set /p DB_NAME=Enter database name [default: hospital_management_system]: 
if "%DB_NAME%"=="" set DB_NAME=hospital_management_system

set /p MYSQL_PWD=Enter MySQL root password (leave blank if none): 

set "SQL_DIR=PUT_YOUR_PROJECT/DATABASE_PATH_HERE"

echo Running 01_db_setup.sql ...
if "%MYSQL_PWD%"=="" (
    "C:\xampp\mysql\bin\mysql.exe" -u root < "%SQL_DIR%\01_db_setup.sql"
    # Adjust the path above to your MySQL executable location
) else (
    "C:\xampp\mysql\bin\mysql.exe" -u root -p%MYSQL_PWD% < "%SQL_DIR%\01_db_setup.sql"
    # Adjust the path above to your MySQL executable location
)

for %%f in ("%SQL_DIR%\02*.sql" "%SQL_DIR%\03*.sql" "%SQL_DIR%\04*.sql" "%SQL_DIR%\05*.sql" "%SQL_DIR%\06*.sql" "%SQL_DIR%\07*.sql") do (
    echo Running %%~nxf ...
    if "%MYSQL_PWD%"=="" (
        "C:\xampp\mysql\bin\mysql.exe" -u root %DB_NAME% < "%%f"
        # Adjust the path above to your MySQL executable location
    ) else (
        "C:\xampp\mysql\bin\mysql.exe" -u root -p%MYSQL_PWD% %DB_NAME% < "%%f"
        # Adjust the path above to your MySQL executable location
    )
)

echo All scripts executed successfully.
pause