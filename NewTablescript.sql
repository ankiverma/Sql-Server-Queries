
CREATE TABLE [dbo].[CustomerCategoryMapping](
	[CustomerCategoryMappingID] [int] IDENTITY(1,1) NOT NULL,
	[CustomerID] [int] NOT NULL,
	[CategoryName] [varchar](200) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedOn] [datetime] NULL,
	[CreatedBy] [int] NULL,
 CONSTRAINT [PK_CustomerCategoryMapping] PRIMARY KEY CLUSTERED 
(
	[CustomerCategoryMappingID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Default [DF_CustomerCategoryMapping_IsActive]    Script Date: 01/11/2017 16:41:05 ******/
ALTER TABLE [dbo].[CustomerCategoryMapping] ADD  CONSTRAINT [DF_CustomerCategoryMapping_IsActive]  DEFAULT ((1)) FOR [IsActive]

