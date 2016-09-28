//: Playground - noun: a place where people can play

import UIKit


//****************************************************************
//              Two-Phase Compiler
//****************************************************************
enum Token {
    case Number(Int)
    case Plus
    case Minus
}

class Lexer {
    //create own error type
    enum Error: Swift.Error {
        case InvalidCharacter(Character, Int)
    }
    let input: String.CharacterView
    var position: String.CharacterView.Index
    
    init(input: String){
        self.input = input.characters
        self.position = self.input.startIndex
        print(self.position)
    }
    //function that peeks at next character so COULD be nil
    func peek() -> Character? {
        //guard is safe way to check possible nil
        //ensures you have not reached end of input (use for all arrays?)
        guard position < input.endIndex else {
            return nil
        }
        return input[position]
    }
    func advance() {
        //old way was
        //++position
        //check for nonrecoverable error
        assert(position < input.endIndex, "Cannot advance past the end!")
            //first arg is codition to check
            //second arg is what happens if cond is false (if true then nothing)
            //only evalualted in debug mode (use precondition(_:_) for release)
    
       position = input.index(after: position)
        
    }
    //function that builds up ints one digit at a time
    var digitLength = 0
    func getNumber() -> Int{
        var value = 0
        
        while let nextCharacter = peek() {
            switch nextCharacter {
                case "0" ... "9":
                    //Another digit - add it into value
                    let digitValue = Int(String(nextCharacter))!
                    value = 10*value + digitValue
                    
                    advance()
                    digitLength = digitLength + 1
                default:
                    //A non-digit - go back to regular lexing
                    return value
            }
        }
        return value
    }
    func rNumber(token: Token) -> Int{
        let token = token
        
        switch token.self{
            case .Number(let value):
                return value
            default:
                print("should never happen")
                break
        }
        return 0
    }
    //indicate function might emit error add throws
    
    func lex() throws -> ([Token], [Int]){
        var tokens = [Token]()
        var count = 0
        var didM = false
        var didD = false
        var countSpot = [Int]()
        while let nextCharacter = peek() {
            switch nextCharacter {
                case "0" ... "9":
                    //tokenIndex.append(Int(String(describing: position))!)
                    let value = getNumber()
                    countSpot.append(count)
                    count = count + digitLength
                    digitLength = 0
                    if didM == true{
                        print("debug")
                        tokens[(tokens.count)-1] = .Number(value * rNumber(token: tokens[(tokens.count)-1]))
                        didM = false
                    }else if didD == true{
                        print("debugDivison")
                        value
                        tokens[(tokens.count)-1] = .Number(rNumber(token: tokens[(tokens.count)-1]) / value)
                        didD = false
                    }else{
                        tokens.append(.Number(value))
                        
                        //print(digitLength)
                        
                    }
                case "+":
                   // tokenIndex.append(Int(String(describing: position))!)
                    tokens.append(.Plus)
                    countSpot.append(count)
                    count = count + 1
                    advance()
                case "-":
                   // tokenIndex.append(Int(String(describing: position))!)
                    tokens.append(.Minus)
                    countSpot.append(count)
                    count = count + 1
                    advance()
                case "*":
                    if didM == false{
                        didM = true
                        print("yes")
                    }else{
                        throw Error.InvalidCharacter(nextCharacter, count+1)
                    }
                    countSpot.append(count)
                    count = count + 1
                    advance()
                case "/":
                    
                    if didD == false{
                        didD = true
                        print("yes")
                    }else{
                        throw Error.InvalidCharacter(nextCharacter, count+1)
                    }
                    countSpot.append(count)
                    print(count)
                    count = count + 1
                    advance()
                case " ":
                    //ignore spaces just continue
                    advance()
                    count = count + 1
                default:
                    throw Error.InvalidCharacter(nextCharacter, count)
            }
        }
           // tokenIndex
            countSpot
           return (tokens, countSpot)
    }
}
//create a parser class!
//*****rules********
//first token must be number
//after number is parsed, either at end of input or next token must be .Plus
//after a .Plus next token must be number
class Parser {
    //create errors
    enum Error: Swift.Error {
        case UnexpectedEndOfInput
        case InvalidTokenSign(Token, Int)
        case InvalidToken(Int, Int)
    }
    
    let tokens: [Token]
    let count: [Int]
    //var tokenCounter = 0
    var position = 0
    
    init(tokens: [Token], count: [Int]) {
        self.tokens = tokens
        self.count = count
    }
    
    func getNextToken() -> Token? {
        guard position < tokens.count else {
            return nil
        }
        tokens[position]
        return tokens[position]
        
        
    }
    
    //gets value of next .Number or throws error
    func getNumber() throws -> Int {
        guard let token = getNextToken() else {
            throw Error.UnexpectedEndOfInput
        }
    
        switch token {
        case .Number(let value):
            position = position + 1
            return value
        case .Plus:
            throw Error.InvalidTokenSign(tokens[position], count[position])
        case .Minus:
            throw Error.InvalidTokenSign(tokens[position], count[position])
        }
        
    }
    
    //parse method that completes parse
    //you can use a try without a do/catch because you can handle error
    //by throwing it again!
    func parse() throws -> (Int) {
        //require number first
        var value = try getNumber()
        
        while let token = getNextToken() {
            switch token {
                
            //get plus after a number is legal
            case .Plus:
                //after plus, must get number
                position = position + 1
                let nextNumber = try getNumber()
                value += nextNumber
            case .Minus:
                position = position + 1
                let nextNumber = try getNumber()
                value -= nextNumber
                
            //getting number after number is not legal
            case .Number:
                let errNum = try getNumber()
                throw Error.InvalidToken(errNum, count[position-1])
               
                
            }
        }
        return value
    }
}


//evaluate lexer
func evaluate(input: String) {
    print("Evaluating \(input)")
    let lexer = Lexer(input: input)
    do {
        let (tokens, count) = try lexer.lex()
        print("Lexer output: \(tokens)")
        let parser = Parser(tokens: tokens, count: count)
        let result = try parser.parse()
        print("Parser output: \(result)")
    } catch Lexer.Error.InvalidCharacter(let (character, index)) {
        print("Input contained an invalid character at index \(index): \(character)")
    } catch Parser.Error.UnexpectedEndOfInput {
        print("Unexpected end of input during parsing")
    } catch Parser.Error.InvalidToken(let (token, count)) {
        print("Invalid token during parsing at index \(count): \(token)")
    }catch Parser.Error.InvalidTokenSign(let (token, count)) {
        print("Invalid token during parsing at index \(count): \(token)")
    }
    catch {
        print("An error occurred: \(error)")
    }
}
evaluate(input: "10 / 3 + 3 + 5 + 3")
//evaluate(input: "1 + 2 + abcfedf")
//evaluate(input: "5 + 10 - 4")



