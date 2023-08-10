/* 

CLEANING DATA IN SQL QUERIES

*/


Select *
From PortfolioProject_2.dbo.NashvilleHousing


--------------------------------------------------------------------------------------------------------

-- Standardize Date Format

Select SaleDate, convert(Date, SaleDate)
From PortfolioProject_2.dbo.NashvilleHousing


Alter Table NashvilleHousing
Add SaleDateConverted Date; -- Data type is "Date"


Update NashvilleHousing
Set SaleDateConverted = convert(Date, SaleDate)


Select SaleDateConverted, convert(Date, SaleDate) -- To compare if it works
From PortfolioProject_2.dbo.NashvilleHousing


--------------------------------------------------------------------------------------------------------

-- Populate Property Address data (no more blank spaces)

Select PropertyAddress
From PortfolioProject_2.dbo.NashvilleHousing
Where PropertyAddress is Null


-- The ParcelID is going to be the same as the PropertyAddress. Useful when PropertyAddress is Null.
-- We have to do a self Join, also considering that UniqueID is always distinct.


Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress 
From PortfolioProject_2.dbo.NashvilleHousing as a
Join PortfolioProject_2.dbo.NashvilleHousing as b
	On a.ParcelID = b.ParcelID
	And a.[UniqueID ] <> b.[UniqueID ] -- ParcelID is the same but it is not the same row.
Where a.PropertyAddress is Null


-- Now, we have to check the NULLs and populate them with their counterpart from the same ParcelID with "ISNULL()"
--Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, Isnull(a.PropertyAddress, b.PropertyAddress)
--From PortfolioProject_2.dbo.NashvilleHousing as a
--Join PortfolioProject_2.dbo.NashvilleHousing as b
--	On a.ParcelID = b.ParcelID
--	And a.[UniqueID ] <> b.[UniqueID ] 
--Where a.PropertyAddress is Null


-- When Updating Joins, we must use the ALIAS
Update a 
Set PropertyAddress = Isnull(a.PropertyAddress, b.PropertyAddress)
From PortfolioProject_2.dbo.NashvilleHousing as a
Join PortfolioProject_2.dbo.NashvilleHousing as b
	On a.ParcelID = b.ParcelID
	And a.[UniqueID ] <> b.[UniqueID ] 
Where a.PropertyAddress is Null


--------------------------------------------------------------------------------------------------------

-- Breaking out Address into individual columns (Address, City, State)

Select PropertyAddress
From PortfolioProject_2.dbo.NashvilleHousing


Select
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address -- Going to the , and then back one slot from it.
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, len(PropertyAddress)) as City -- +1 to eliminate de coma.
From PortfolioProject_2.dbo.NashvilleHousing


-- Creating new column for the Address (at the end)
Alter Table NashvilleHousing
Add PropertySplitAdddress nvarchar(255);


Update NashvilleHousing
Set PropertySplitAdddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)


-- ...And another one  for the City (at the end)
Alter Table NashvilleHousing
Add PropertySplitCity nvarchar(255);


Update NashvilleHousing
Set PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, len(PropertyAddress))


--Select *
--From PortfolioProject_2.dbo.NashvilleHousing


-- Now a simpler way to do the same process to OwnerAddress. PARSENAME()
Select 
Parsename(Replace(OwnerAddress, ',', '.'), 3), -- Looks for periods, not commas!
Parsename(Replace(OwnerAddress, ',', '.'), 2), -- Function works in descending order
Parsename(Replace(OwnerAddress, ',', '.'), 1)
From PortfolioProject_2.dbo.NashvilleHousing


Alter Table NashvilleHousing
Add OwnerSplitAddress nvarchar(255);


Update NashvilleHousing
Set OwnerSplitAddress = Parsename(Replace(OwnerAddress, ',', '.'), 3)


Alter Table NashvilleHousing
Add OwnerSplitCity nvarchar(255);

Update NashvilleHousing
Set OwnerSplitCity = Parsename(Replace(OwnerAddress, ',', '.'), 2)


Alter Table NashvilleHousing
Add OwnerSplitState nvarchar(255);

Update NashvilleHousing
Set OwnerSplitState = Parsename(Replace(OwnerAddress, ',', '.'), 1)


--Select *
--From PortfolioProject_2.dbo.NashvilleHousing


--------------------------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in "Sold as Vacant" field

Select Distinct(SoldAsVacant), count(SoldAsVacant)
From PortfolioProject_2.dbo.NashvilleHousing
Group by SoldAsVacant
Order by 2



Select SoldAsVacant
, Case When SoldAsVacant = 'Y' Then 'Yes'
	   When SoldAsVacant = 'N' Then 'No'
	   Else SoldAsVacant -- If is neither Y or N, keep it how it is
	   End
From PortfolioProject_2.dbo.NashvilleHousing


Update NashvilleHousing
Set SoldAsVacant = Case When SoldAsVacant = 'Y' Then 'Yes'
	   When SoldAsVacant = 'N' Then 'No'
	   Else SoldAsVacant -- If is neither Y or N, keep it how it is
	   End


--------------------------------------------------------------------------------------------------------

-- Remove Duplicates

With RowNumCTE as ( -- We can do this whole process with a CTE or Temp Table.
Select *,
	ROW_NUMBER() Over(
	Partition by ParcelID, -- We need to partition by something that is unique to each row
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 Order by
					UniqueID
					) as row_num
From PortfolioProject_2.dbo.NashvilleHousing
--Order by ParcelID
)
Delete -- Instead of Select
From RowNumCTE
Where row_num > 1 -- Duplicates are shown '2' and above. 
--Order by PropertyAddress


--------------------------------------------------------------------------------------------------------

-- Delete Unused Columns

Alter Table PortfolioProject_2.dbo.NashvilleHousing
Drop Column OwnerAddress, PropertyAddress, TaxDistrict, SaleDate


--Select *
--From PortfolioProject_2.dbo.NashvilleHousing


--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------