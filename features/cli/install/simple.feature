Feature: Installing
  As a user i want to install a pkg from a local or
  remote location so that i can start right away using
  my newly configured system

  Background:
    Given a package named "cassia/simple" with the following manifest:
    """
    ---
    config_files:
      - bashrc
    """
    And an empty file named "cassia/simple/bashrc"


  Scenario: Installing from a local directory
    When I run `lace fetch cassia/simple`
    And I run `lace setup simple`
    And I run `lace ls`
    Then the output should contain:
    """
    [*] simple
    """
    And the following files should exist:
      | HOME/.bashrc |

  Scenario: Installing from a local directory twice
    When I run `lace fetch cassia/simple`
    And I run `lace setup simple`
    When I run `lace fetch cassia/simple`
    Then the output should contain:
    """
    Package already installed
    """
    And the following files should exist:
      | HOME/.bashrc |

  Scenario: Installing from a local directory with a name
    When I run `lace fetch cassia/simple --name=mypkg`
    And I run `lace setup mypkg`
    And I run `lace ls`
    Then the output should contain:
    """
    [*] mypkg
    """
    And the following files should exist:
      | HOME/.bashrc |

  Scenario: Installing from a local directory with a name
    When I run `lace fetch cassia/simple --name=mypkg`
    And I run `lace setup mypkg`
    And I run `lace ls`
    Then the output should contain:
    """
    [*] mypkg
    """
    And the following files should exist:
      | HOME/.bashrc |

  Scenario: Installing from a local directory without a .lace.yml
    Given a directory named "cassia/nopkg"
    And an empty file named "cassia/nopkg/bashrc"
    When I run `lace fetch cassia/nopkg`
    Then the output should contain:
    """
    Error: Removing fetched files
    """
    And the output should contain "No PackageFacts found in"
    When I run `lace ls`
    Then the output should contain:
    """
    There are no pkgs installed
    """

