/*

Cleaning Data in SQL Queries

*/
----------------------------------------------------------------------------------------
-- Standardize Date Format
ALTER TABLE portfolioproject..nashvillehousing
  ADD saledate1 DATE;

UPDATE portfolioproject..nashvillehousing
SET    saledate1 = CONVERT(DATE, saledate) /* saledate no longer exists.
                                            Its column is droped later on. */
----------------------------------------------------------------------------------------

-- Populate Property Address data (Find rows in PropertyAddress that are Null but have a matching address
SELECT *
FROM   portfolioproject.dbo.nashvillehousing
ORDER  BY parcelid

SELECT t1.parcelid,
       t1.propertyaddress,
       t2.parcelid,
       t2.propertyaddress,
       Isnull(t1.propertyaddress, t2.propertyaddress)
FROM   portfolioproject.dbo.nashvillehousing t1
       JOIN portfolioproject.dbo.nashvillehousing t2
         ON t1.parcelid = t2.parcelid
            AND t1.[uniqueid] <> t2.[uniqueid]
WHERE  t1.propertyaddress IS NULL

UPDATE t1
SET    t1.propertyaddress = Isnull(t1.propertyaddress, t2.propertyaddress)
FROM   portfolioproject.dbo.nashvillehousing t1
       JOIN portfolioproject.dbo.nashvillehousing t2
         ON t1.parcelid = t2.parcelid
            AND t1.[uniqueid] <> t2.[uniqueid]
WHERE  t1.propertyaddress IS NULL

----------------------------------------------------------------------------------------
-- Breaking out Address into Individual Columns (Address, City)
SELECT *
FROM   portfolioproject..nashvillehousing

SELECT Substring(propertyaddress, 1, Charindex(',', propertyaddress) - 1) AS
       PropertyStreetSplit,
       Substring(propertyaddress, Charindex(',', propertyaddress) + 1, Len(
       propertyaddress))                                                  AS
       PropertyCitySplit
FROM   portfolioproject..nashvillehousing

ALTER TABLE portfolioproject..nashvillehousing
  ADD propertystreetsplit NVARCHAR(255), propertycitysplit NVARCHAR(255);

UPDATE portfolioproject..nashvillehousing
SET    propertystreetsplit = Substring(propertyaddress, 1,
                                    Charindex(',', propertyaddress) - 1),
       propertycitysplit = Substring(propertyaddress,
                           Charindex(',', propertyaddress) +
                           1, Len(
                                               propertyaddress))

-- Breaking out Address into Individual Columns (Address, City, State)
SELECT *
FROM   portfolioproject..nashvillehousing

SELECT Parsename(Replace(owneraddress, ',', '.'), 3) AS Address,
       Parsename(Replace(owneraddress, ',', '.'), 2) AS City,
       Parsename(Replace(owneraddress, ',', '.'), 1) AS State
FROM   portfolioproject..nashvillehousing

ALTER TABLE portfolioproject..nashvillehousing
  ADD ownersplitstate NVARCHAR(255), ownersplitcity NVARCHAR(255),
  ownersplitaddress NVARCHAR(255);

UPDATE portfolioproject..nashvillehousing
SET    ownersplitstate = Parsename(Replace(owneraddress, ',', '.'), 1),
       ownersplitcity = Parsename(Replace(owneraddress, ',', '.'), 2),
       ownersplitaddress = Parsename(Replace(owneraddress, ',', '.'), 3);

----------------------------------------------------------------------------------------
-- Change Y and N to Yes and No in "Sold as Vacant" field
SELECT DISTINCT( soldasvacant ),
               Count(soldasvacant)
FROM   portfolioproject..nashvillehousing
GROUP  BY soldasvacant

SELECT soldasvacant,
       CASE
         WHEN soldasvacant = 'Y' THEN 'Yes'
         WHEN soldasvacant = 'N' THEN 'No'
         ELSE soldasvacant
       END
FROM   portfolioproject..nashvillehousing

UPDATE portfolioproject..nashvillehousing
SET    soldasvacant = CASE
                        WHEN soldasvacant = 'Y' THEN 'Yes'
                        WHEN soldasvacant = 'N' THEN 'No'
                        ELSE soldasvacant
                      END

----------------------------------------------------------------------------------------
-- Remove Duplicates
WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyStreetSplit,
				 PropertyCitySplit,
				 SalePrice,
				 saledate1,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

FROM   portfolioproject..nashvillehousing
--ORDER BY ParcelID
)

/*
DELETE
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyStreetSplit
*/

-- Checking if any duplicates remain
SELECT *
FROM RowNumCTE
WHERE row_num > 1

----------------------------------------------------------------------------------------
-- Delete Unused Columns
ALTER TABLE portfolioproject..nashvillehousing
  DROP COLUMN saledate, owneraddress, propertyaddress, taxdistrict 