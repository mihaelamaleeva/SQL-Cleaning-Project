USE nh;

SELECT * 
FROM nh.dbo.housings
ORDER BY ParcelID

-- Converting SaleDate to date format and adding it into new column

SELECT CAST(SaleDate as date),SaleDate
FROM housings

ALTER TABLE housings
ADD  SaleDateConverted DATE

UPDATE housings
SET SaleDateConverted = CONVERT(date,SaleDate)


-- Populating null property addresses  

SELECT b.PropertyAddress
FROM housings a
JOIN housings b 
ON a.UniqueID <> b.UniqueID 
AND a.ParcelID = b.ParcelID
WHERE a.PropertyAddress IS NULL 

UPDATE a
SET  a.PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM housings a
JOIN housings b 
	ON a.UniqueID <> b.UniqueID 
	AND a.ParcelID = b.ParcelID					
WHERE a.PropertyAddress IS NULL

-- Converting SoldAsVacant in standard fromat
SELECT (CASE
			 WHEN SoldAsVacant = 'Y' THEN 'Yes'
			 WHEN SoldAsVacant = 'N' THEN 'No'
			 ELSE SoldAsVacant
		END) AS SoldAsVacant
FROM housings

UPDATE housings 
SET SoldAsVacant = (CASE
		 WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
		 END)

-- Split ProprtyAdress into street and city
SELECT DISTINCT SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1,len(PropertyAddress)) AS city
FROM housings

SELECT  SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1,len(PropertyAddress)) AS city,
		SUBSTRING(PropertyAddress,0,CHARINDEX(',',PropertyAddress)-1) AS street
FROM housings

ALTER TABLE housings
ADD  PropertyStreet VARCHAR(100) ,
	 PropertyCity VARCHAR(40) 



UPDATE housings 
SET PropertyStreet = SUBSTRING(PropertyAddress,0,CHARINDEX(',',PropertyAddress)-1),
PropertyCity  = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1,len(PropertyAddress))

-- Fixing misspelled LandUse types

SELECT LandUse,SoldAsVacant,Count(SoldAsVacant)
FROM housings
GROUP BY LandUse,SoldAsVacant
ORDER BY LandUse

SELECT LandUse, IIF (left(LandUse,10) = 'VACANT RES','VACANT RESIDENTIAL LAND' ,LandUse) 
FROM housings
WHERE left(LandUse,10) = 'VACANT RES'

UPDATE housings
SET LandUse = IIF (left(LandUse,10) = 'VACANT RES','VACANT RESIDENTIAL LAND' ,LandUse)

-- Removing Duplicates	
WITH CTE(ParcelID, 
    SaleDate, 
    LegalReference, 
    duplicatecount)
AS (SELECT ParcelID, 
           SaleDate, 
           LegalReference, 
           ROW_NUMBER() OVER(PARTITION BY ParcelID, 
                                          SaleDate, 
                                          LegalReference
           ORDER BY UniqueID) AS duplicatecount
    FROM housings)
DELETE 
FROM CTE
WHERE duplicatecount >1 ;

