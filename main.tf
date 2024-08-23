data "azurerm_resource_group" "sroland-sandbox" {
  name = "sroland-sandbox"
}

# Create virtual network
resource "azurerm_virtual_network" "terra_chal_network" {
  name                = "${var.prefix}vnet"
  address_space       = ["10.0.0.0/16"]
  location            = data.azurerm_resource_group.sroland-sandbox.location
  resource_group_name = data.azurerm_resource_group.sroland-sandbox.name
}

# Create Web subnet
resource "azurerm_subnet" "terra_chal_Web_subnet" {
  name                 = "${var.prefix}Web-subnet"
  resource_group_name  = data.azurerm_resource_group.sroland-sandbox.name
  virtual_network_name = azurerm_virtual_network.terra_chal_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create Web subnet
resource "azurerm_subnet" "terra_chal_Data_subnet" {
  name                 = "${var.prefix}Data-subnet"
  resource_group_name  = data.azurerm_resource_group.sroland-sandbox.name
  virtual_network_name = azurerm_virtual_network.terra_chal_network.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Create Web subnet
resource "azurerm_subnet" "terra_chal_Jumpbox_subnet" {
  name                 = "${var.prefix}Jumpbox-subnet"
  resource_group_name  = data.azurerm_resource_group.sroland-sandbox.name
  virtual_network_name = azurerm_virtual_network.terra_chal_network.name
  address_prefixes     = ["10.0.3.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "terra_chal_pub_win_ip" {
  name                = "${var.prefix}public_win-ip"
  location            = data.azurerm_resource_group.sroland-sandbox.location
  resource_group_name = data.azurerm_resource_group.sroland-sandbox.name
  allocation_method   = "Dynamic"
}

# Create public IPs
resource "azurerm_public_ip" "terra_chal_pub_linux_ip" {
  name                = "${var.prefix}public_linux-ip"
  location            = data.azurerm_resource_group.sroland-sandbox.location
  resource_group_name = data.azurerm_resource_group.sroland-sandbox.name
  allocation_method   = "Dynamic"
}

# Create Network Security Group and rules
resource "azurerm_network_security_group" "terra_chal_nsg" {
  name                = "${var.prefix}nsg"
  location            = data.azurerm_resource_group.sroland-sandbox.location
  resource_group_name = data.azurerm_resource_group.sroland-sandbox.name

  security_rule {
    name                       = "RDP"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "web"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "terra_chal_win_nic" {
  name                = "${var.prefix}nic"
  location            = data.azurerm_resource_group.sroland-sandbox.location
  resource_group_name = data.azurerm_resource_group.sroland-sandbox.name

  ip_configuration {
    name                          = "my_nic_configuration"
    subnet_id                     = azurerm_subnet.terra_chal_Web_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.terra_chal_pub_win_ip.id
  }
}

# Create network interface
resource "azurerm_network_interface" "terra_chal_linux_nic" {
  name                = "${var.prefix}nic1"
  location            = data.azurerm_resource_group.sroland-sandbox.location
  resource_group_name = data.azurerm_resource_group.sroland-sandbox.name

  ip_configuration {
    name                          = "my_nic_configuration"
    subnet_id                     = azurerm_subnet.terra_chal_Web_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.terra_chal_pub_linux_ip.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "Windows" {
  network_interface_id      = azurerm_network_interface.terra_chal_win_nic.id
  network_security_group_id = azurerm_network_security_group.terra_chal_nsg.id
}

resource "azurerm_network_interface_security_group_association" "Linux" {
  network_interface_id      = azurerm_network_interface.terra_chal_linux_nic.id
  network_security_group_id = azurerm_network_security_group.terra_chal_nsg.id
}

# Create virtual machine
resource "azurerm_windows_virtual_machine" "Terra_chal_win_vm" {
  name                  = "${var.prefix}vm"
  admin_username        = "azureuser"
  admin_password        = var.password
  location              = data.azurerm_resource_group.sroland-sandbox.location
  resource_group_name   = data.azurerm_resource_group.sroland-sandbox.name
  network_interface_ids = [azurerm_network_interface.terra_chal_win_nic.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "WinOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "Terra_chal_SA" {
  name                     = "srolandboot"
  location                 = data.azurerm_resource_group.sroland-sandbox.location
  resource_group_name      = data.azurerm_resource_group.sroland-sandbox.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create Linux virtual machine
resource "azurerm_linux_virtual_machine" "terra_chal_linux_vm" {
  name                  = "${var.prefix}linux-vm"
  location              = data.azurerm_resource_group.sroland-sandbox.location
  resource_group_name   = data.azurerm_resource_group.sroland-sandbox.name
  network_interface_ids = [azurerm_network_interface.terra_chal_linux_nic.id]
  size                  = "Standard_DS1_v2"
 
  os_disk {
    name                 = "LinuxOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
 
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
 
  computer_name  = "hostname"
  admin_username = var.username
  admin_password = var.password
 
  admin_ssh_key {
    username   = var.username
    public_key = azapi_resource_action.ssh_public_key_gen.output.publicKey
  }
 
  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.Terra_chal_SA.primary_blob_endpoint
  }
}
 